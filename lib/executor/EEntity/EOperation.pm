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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package EEntity::EOperation;
use base 'EEntity';

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;

use General;
use Entity;
use ERollback;
use EFactory;
use Entity::Operation;
use Operationtype;
use Entity::ServiceProvider::Inside::Cluster;

use Kanopya::Config;
use Kanopya::Exceptions;

my $log = get_logger("");
my $errmsg;
our $VERSION = '1.00';

use vars qw ( $AUTOLOAD );

sub new {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'data' ]);

    my $params  = $args{data}->getParams;
    my $context = $params->{context};
    delete $params->{context};

    my $self = $class->SUPER::new(%args);

    $self->{params} = $params;
    $self->{context} = $context;

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

    my $adm    = Administrator->new();
    my $config = General::getTemplateConfiguration();

    $adm->beginTransaction;

    # Search for all context entites if notification/validation required
    my $validation = 0;
    for my $entity (values %{ $self->getParams->{context} }) {
        $log->debug("Check if notification/validation required for $entity <" . $entity->id . ">");

        # Arg, the foreign key on operationtype is not on the primary key...
        my $operationtype = Operationtype->find(hash => { operationtype_name => $self->type });
        my @subscribtions = NotificationSubscription->search(hash => {
                                entity_id        => $entity->id,
                                operationtype_id => $operationtype->id,
                            });

        for my $subscribtion (@subscribtions) {
            # Try to get the notification manager to use
            my $notifier;
            eval {
                my $component = $subscribtion->service_provider->getManager(
                                    manager_type => 'notification_manager'
                                );

                $notifier = EFactory::newEEntity(data => $component);
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
            #       So try to get the public ip of the kanopya master node, but the port is still hard core.
            my $kanopya = Entity::ServiceProvider::Inside::Cluster->find(hash => { cluster_name => 'Kanopya' });

            my $ip;
            eval {
                $ip = $kanopya->getMasterNode->getPublicIp;
            };
            if ($@) {
                $log->warn("Unable to get the master kanopya public ip, use the admin ip.");
                $ip = $kanopya->getMasterNode->adminIp;
            }

            my $input;
            my $baseurl = "http://" . $ip . ":5000/validation/operation/" . $self->id;

            if ($subscribtion->validation) {
                $input = "validationmail";
                $templatedata->{validation_url} = $baseurl . '/validate';
                $templatedata->{deny_url} = $baseurl . '/deny';

                # Give permissions to the user/group to call validate/cancel methos on the operation.
                $self->addValidationPerm(consumer => $subscribtion->subscriber);

                $validation = 1;
            }
            else {
                $input = "notificationmail";
            }

            my $subject = '';
            $template->process($input . 'subject.tt', $templatedata, \$subject)
                or throw Kanopya::Exception::Internal(
                     error => "Error when processing template " . $input . 'subject.tt'
                 );

            my $message = '';
            $template->process($input . '.tt', $templatedata, \$message)
                or throw Kanopya::Exception::Internal(
                     error => "Error when processing template " . $input . '.tt'
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

    $adm->commitTransaction;

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
    my $self = shift;

    return EFactory::newEContext(ip_source      => $self->{_executor}->getMasterNodeIp(),
                                 ip_destination => $self->{_executor}->getMasterNodeIp());
}

1;

__END__

=pod

=head1 NAME

EOperation - Abstract class of EOperation object.

=head1 SYNOPSIS

    use EOperation;
    use Operation;

    my $operation = Operation->getNexOp();
    my $eoperation = EOperation->new(data => $operation);
    
    $self->{config} = Kanopya::Config::get('executor');
    
    eval {
        $eoperation->prepare();
        $eoperation->process();
    };
    if ($@) {
        $eoperation->cancel();
    } else {
        $o$eoperationp->finish();
    }
    $o$eoperationp->delete();

=head1 DESCRIPTION

EOperation is an abstract class of different operations available in kanopya executor.
Each eoperation could be composed by the following methods.
- prepare (pre-execution)
- process
- finish (post-execution)
EOperations contain :
- _operation : Operation : Operation send by user (human or software).
This attribute is Operation created by user and saved in database. 
This operation is loaded from database by EFactory and stored into EOperation

=head1 METHODS

=head2 new

    Class : Public
    
    Desc : This abstract method creates a new eoperation object.
    
    Args :
        data : Operation : Operation (get from Database)
        
    Return : Eoperation, this class could not be instanciated !!

=head2 prepare

    Class : Public
    
    Desc : This method is the first method execute during eoperation execution.
    Its goal is to prepare the operation execution. In this method args are
    checked, entities and eentities need by operation execution 
    ( ex : cluster, host, component, ecomponent, econtext ...) are load in $self
    
    Args :
        None
        
    Return : Nothing
    
=head2 process

    Class : Public
    
    Desc : This method is the real execution method.
    
    Args :
        None
        
    Return : Nothing
    
=head2 cancel

    Class : Public
    
    Desc : This method cancel changes done during process.
    DB will be rollback by the the transaction cancel
    To backup real change, cancel method call rollback 
    
    Args :
        None
        
    Return : Nothing
    
=head2 finish

    Class : Public
    
    Desc : This method is the last execution operation method called. 
    It is used to clean and finalize operation execution
    
    Args :
        None
        
    Return : Nothing
    
    Throw

=head2 loadContext
    
    Class : Public
    
    Desc : load in $self->{ args{service} }->{econtext} the context correponding to the specified service
    
    Args : service : service name (e.g. 'nas', 'bootserver', 'executor', 'monitor')
    

=head1 DIAGNOSTICS

Exceptions are thrown when mandatory arguments are missing.
Exception : Kanopya::Exception::Internal::IncorrectParam

=head1 CONFIGURATION AND ENVIRONMENT

This module need to be used into Kanopya environment. (see Kanopya presentation)
This module is a part of Administrator package so refers to Administrator configuration

=head1 DEPENDENCIES

This module depends of 

=over

=item KanopyaException module used to throw exceptions managed by handling programs

=item Entity::Component module which is its mother class implementing global component method

=back

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to <Maintainer name(s)> (<contact address>)

Patches are welcome.

=head1 AUTHOR

<HederaTech Dev Team> (<dev@hederatech.com>)

=head1 LICENCE AND COPYRIGHT

Copyright 2011 Hedera Technology SAS
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

