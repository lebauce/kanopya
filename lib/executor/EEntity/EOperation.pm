# Copyright © 2011 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package EEntity::EOperation;
use base 'EEntity';

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;

use General;
use Entity;
use ERollback;
use EEntity;
use Entity::Operation;
use Operationtype;
use Entity::ServiceProvider::Cluster;

use Kanopya::Config;
use Kanopya::Exceptions;

my $log = get_logger("");
my $errmsg;

use vars qw ( $AUTOLOAD );

sub new {
    my $class = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'operation' ],
                         optional => { 'skip_not_found' => 0 });

    my $self = $class->SUPER::new(entity => $args{operation},
                                  eclass => "EEntity::EOperation::E" . $args{operation}->type);

    my $params = $args{operation}->unserializeParams(skip_not_found => $args{skip_not_found});
    $self->{context} = delete $params->{context};
    $self->{params}  = $params;

    return $self;
}

sub prepare {
    my $self = shift;

    $self->{userid}    = $self->user->id;
    $self->{erollback} = ERollback->new();
}

sub process {
    my $self = shift;

    $self->execute();
}

sub cancel {
    my $self = shift;
    $self->_cancel;

    $self->setState(state => 'cancelled');
}

sub prerequisites {
    my $self = shift;

    # Operations are not reported by default.
    return 0;
}

sub postrequisites {
    my $self = shift;

    # Operations are not reported by default.
    return 0;
}

sub validation {
    my $self = shift;
    my %args = @_;

    my $config = General::getTemplateConfiguration();

    $self->beginTransaction;

    # Search for all context entites if notification/validation required
    my $validation = 0;
    for my $entity (values %{ $self->unserializeParams->{context} }) {
        $log->debug("Check if notification/validation required for $entity <" . $entity->id . ">");

        my @subscribtions = NotificationSubscription->search(hash => {
                                entity_id        => $entity->id,
                                operationtype_id => $self->operationtype_id,
                            });

        for my $subscribtion (@subscribtions) {
            # Try to get the notification manager to use
            my $notifier;
            eval {
                my $component = $subscribtion->service_provider->getManager(
                                    manager_type => 'NotificationManager'
                                );

                $notifier = EEntity->new(data => $component);
            };
            if ($@) {
                $log->debug("Unable to get the notification manager for service provider <" .
                            ref($subscribtion->service_provider) . ">, skip notification...");
                next;
            }

            # Create Template object
            my $template = Template->new($config);
            my $templatedata = { operation  => $self->label };

            # TODO: We do not have a mechanism to retreive the url of the web ui...
            #       So try to get the public ip of the kanopya front master node, but the port is still hard coded.
            my $kanopya = Entity::ServiceProvider::Cluster->getKanopyaCluster;

            my $ip;
            eval {
                $ip = $kanopya->getComponent(name => 'KanopyaFront')->getMasterNode->getPublicIp;
            };
            if ($@) {
                $log->warn("Unable to get the master kanopya public ip, use the admin ip.");
                $ip = $kanopya->getComponent(name => 'KanopyaFront')->getMasterNode->adminIp;
            }

            my $input;
            my $baseurl = "http://" . $ip . ":5000/validation/operation/" . $self->id;

            my $message = '';
            if ($subscribtion->validation) {
                $input = "validationmail";
                $templatedata->{validation_url} = $baseurl . '/validate';
                $templatedata->{deny_url} = $baseurl . '/deny';

                # Give permissions to the user/group to call validate/cancel methos on the operation.
                $self->addValidationPerm(consumer => $subscribtion->subscriber);

                $validation = 1;

                $template->process($input . '.tt', $templatedata, \$message)
                    or throw Kanopya::Exception::Internal(
                         error => "Error when processing template " . $input . '.tt'
                     );
            }
            else {
                $input      = "notificationmail";
                $message    = $entity->notificationMessage(operation => $self->_entity);
            }

            my $subject = '';
            $template->process($input . 'subject.tt', $templatedata, \$subject)
                or throw Kanopya::Exception::Internal(
                     error => "Error when processing template " . $input . 'subject.tt'
                 );

            # TODO: Use multi recipient send, instead of sending one mail per subcriber
            eval {
                $notifier->notify(user => $subscribtion->subscriber, subject => $subject, message => $message);
            };
            if ($@) {
                $log->error("Validation notification failled: " . $@);
            }
        }
    }

    $self->commitTransaction;

    return not $validation;
}

sub _cancel {}
sub finish {}
sub execute {}
sub check {}

sub report {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'duration' ]);

    $log->debug("Reporting operation with duration_report : $args{duration}");
    $self->setHopedExecutionTime(value => $args{duration});
}

sub getEContext {
    my ($self, %args) = @_;

    return $self->_host->getEContext;
}

1;
