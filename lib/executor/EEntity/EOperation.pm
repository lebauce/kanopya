# Copyright © 2011-2014 Hedera Technology SAS
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

=pod
=begin classdoc

The execution lib for the class Operation.
The Execution daemon instantiate EOperations from operations.

=end classdoc
=cut

package EEntity::EOperation;
use base EEntity;

use strict;
use warnings;

use General;
use Entity;
use ERollback;
use EEntity;
use Entity::Operation;
use Operationtype;
use NotificationSubscription;
use Entity::ServiceProvider::Cluster;

use Kanopya::Config;
use Kanopya::Exceptions;
use Kanopya::Database;

use TryCatch;
use Data::Dumper;
use Log::Log4perl "get_logger";
my $log = get_logger("");


=pod
=begin classdoc

@contructor

EOperation factory, instantiate the proper concrete EOperation from
the operation type, unserialize the parameters from tha json stored in database
and keep them as private field.
The parameters are splited in two categories:
 - params: regular parameters as scalar, list, or hash parameters
 - context: execution entities instanciated from the ids stored in dabatase, context objects
            are r/w locked during the following operation steps: prepare, finish and cancel.
            This is during thoses steps that the states of the execution entities can be
            updated atomically.

@param operation the operation

@return the EOperation instance

=end classdoc
=cut

sub new {
    my ($class, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'operation' ],
                         optional => { 'skip_not_found' => 0 });

    my $self = $class->SUPER::new(entity => $args{operation},
                                  eclass => "EEntity::EOperation::E" . $args{operation}->type);

    # Set the unserialized params as private fields
    my $params = $self->unserializeParams(skip_not_found => $args{skip_not_found});
    $self->{context} = delete $params->{context};
    $self->{params}  = $params;

    # Instanciate an erollback for commands roll backs
    $self->{erollback} = ERollback->new();

    return $self;
}


=pod
=begin classdoc

Check required parameters for the operation execution.
Do nothing if not overriden in the concrete operation.

=end classdoc
=cut

sub check {
    my ($self, %args) = @_;
}


=pod
=begin classdoc

Make some verification about the infrastructure, could throw errors.
As the context entities are locked during this step, here is proper
place to update states of the context entities, consumming ressources
atomically.

Do nothing if not overriden in the concrete operation.

=end classdoc
=cut

sub prepare {
    my ($self, %args) = @_;
}


=pod
=begin classdoc

Ensure all prerequisites for the operation execution,
like resources availability.
If a resource not available or a device not responding yet,
the operation can be reported about a specified amount of seconds.
Ths step can also be used to prepend an ambedded workflow and
report the operation, and so execute a required workflow before
retrying the current operation.

Do nothing if not overriden in the concrete operation.

=end classdoc
=cut

sub prerequisites {
    my ($self, %args) = @_;

    # Operations are not reported by default.
    return 0;
}


=pod
=begin classdoc

Here is the real job of the operation. Keep ti as simple as possible,
ideally a call to a method of an execution entity of the context only.

Do nothing if not overriden in the concrete operation.

=end classdoc
=cut

sub execute {
    my ($self, %args) = @_;
}


=pod
=begin classdoc

Processed at the end of successful operation, used to change
the states of the execution entities of the context, or to
remove some execution entities from the context.
As the context entities are locked during this step, here is proper
place to restore states of the context entities, releasing ressources
atomically.

Do nothing if not overriden in the concrete operation.

=end classdoc
=cut

sub finish {
    my ($self, %args) = @_;
}


=pod
=begin classdoc

Here is the job that cancel all creations or modifications done
at the execute step. Called on on all executed operation of a
failed workflow.
As the context entities are locked during this step, here is proper
place to restore states of the context entities, releasing ressources
atomically.

Do nothing if not overriden in the concrete operation.

=end classdoc
=cut

sub cancel {
    my ($self, %args) = @_;
}


=pod
=begin classdoc

Same mechanism as prerequisites, but processed after the execute step.
Commonly used to append embedded workflows ater a successfull workflow execution.

Do nothing if not overriden in the concrete operation.

=end classdoc
=cut

sub postrequisites {
    my ($self, %args) = @_;

    # Operations are not reported by default.
    return 0;
}


=pod
=begin classdoc

Report the operation execution by increasing the hoped executoin time.

@param duration the report duration in seconds

=end classdoc
=cut

sub report {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'duration' ]);

    $log->info("Reporting operation with duration_report : $args{duration}");
    $self->setHopedExecutionTime(value => $args{duration});
}


=pod
=begin classdoc

Handle state modifcation of the operation, and proccess all
notifications set on this operation for this state

@param state the operation state to set

=end classdoc
=cut

sub setState {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'state' ], optional => { 'reason' => undef });

    # For each entity in the context, check if notifiaction/validation are set for this state
    # If at least one require validation, the operation do not change this state,
    # and validation is requested to caller.
    my $validation = $self->processNotificationSubscriptions(state  => $args{state},
                                                             reason => $args{reason});
    if ($validation) {
        throw Kanopya::Exception::Execution::OperationRequireValidation();
    }

    # Propagate the state modification
    $self->state($args{state});
}


=pod
=begin classdoc

Browse the entities in the operation context, and send notifications if
subscriptions has been set.

@param state the operation state to set

@return flag to require validation or not

=end classdoc
=cut

sub processNotificationSubscriptions {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'state' ]);

    # For each entity in the operation context, check for notification/validation subscriptions
    my $validation = 0;
    for my $entity (grep { defined $_ } values %{ $self->{context} }) {
        my @subscriptions = $entity->search(
                                related => 'notification_subscriptions',
                                hash    => {
                                    operationtype_id => [ $self->operationtype_id, undef ],
                                    operation_state  => $args{state}
                                }
                            );

        # TODO: Use multi recipient send, instead of sending one mail per subcriber
        for my $subscription (@subscriptions) {
            # Try to get the notification manager to use
            my $notifier;
            try {
                $notifier = $subscription->service_provider->getManager(
                                manager_type => 'NotificationManager'
                            );
            }
            catch ($err) {
                $log->warn("Unable to get the notification manager for service provider <" .
                            ref($subscription->service_provider) . ">, skip notification...");
                next;
            }

            # Check for validation set for the state 'processing'
            # (the only state supported for validation yet)
            my ($subject, $message);
            if ($args{state} eq 'processing' && $subscription->validation && $self->state ne 'validated') {
                # Give permissions to the user/group to call validate/cancel method on the operation.
                $self->addValidationPerm(consumer => $subscription->subscriber);

                # Get the message depending of the subscription entity type
                ($subject, $message) = $self->validationMessage();

                $validation = 1;
            }
            else {
                if ($subscription->validation) {
                    $log->warn("Validation for operation state \"" . $args{state} .
                               "\" not supported, ignoring...");
                }
                # Get the message depending of the subscription entity type
                ($subject, $message) = $entity->notificationMessage(operation  => $self,
                                                                    state      => $args{state},
                                                                    reason     => $args{reason},
                                                                    subscriber => $subscription->subscriber);
            }

            # Finally notify the user.
            try {
                $log->info("Send notification message to user " . $subscription->subscriber->user_login);
                $notifier->notify(user    => $subscription->subscriber,
                                  subject => $subject,
                                  message => $message);
            }
            catch ($err) {
                $log->error("Notification to " . $subscription->subscriber->user_login . " failed:\n$err");
            }
        }
    }
    return $validation;
}


=pod
=begin classdoc

Build the operation validation message.

@return the validation message

=end classdoc
=cut

sub validationMessage {
    my ($self, %args) = @_;

    my $template = Template->new(General::getTemplateConfiguration());

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

    my $baseurl = "http://" . $ip . ":5000/validation/operation/" . $self->id;
    my $templatedata = {
        operation      => $self->label,
        validation_url => $baseurl . '/validate',
        deny_url       => $baseurl . '/deny',
    };

    my $message = "";
    $template->process('validationmail.tt', $templatedata, \$message)
        or throw Kanopya::Exception::Internal(
             error => "Error when processing template validationmail.tt"
         );

    my $subject = "";
    $template->process('validationmailsubject.tt', $templatedata, \$subject)
        or throw Kanopya::Exception::Internal(
             error => "Error when processing template validationmailsubject.tt"
         );

    return ($subject, $message);
}


=pod
=begin classdoc

Instanciate execution entities for context entities.

@return the params hash

=end classdoc
=cut

sub unserializeParams {
    my ($self, %args) = @_;

    my $params = $self->_entity->unserializeParams(%args);
    map { $params->{context}->{$_} = EEntity->new(data => $params->{context}->{$_}) }
        keys %{ (defined $params->{context} ? $params->{context} : {}) };

    return $params;
}


=pod
=begin classdoc

An operation use the local context for execution.
Use with caution, the local econtext execute commands on
the executor node where the operation is processing, and
it can be different for the next operation.

=end classdoc
=cut

sub getEContext {
    my ($self, %args) = @_;

    return $self->_host->getEContext;
}

1;
