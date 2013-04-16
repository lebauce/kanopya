#    Copyright © 2011-2013 Hedera Technology SAS
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package Entity::Operation;
use base 'Entity';

use strict;
use warnings;

use General;
use Entity::Workflow;
use Operationtype;
use ParamPreset;
use Kanopya::Exceptions;
use NotificationSubscription;
use OldOperation;
use DateTime;
use Hash::Merge;

use Data::Dumper;
use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    operationtype_id => {
        pattern      => '^\d+$',
        is_mandatory => 1,
    },
    state => {
        pattern      => '^ready|processing|prereported|postreported|waiting_validation|' .
                        'validated|blocked|cancelled|succeeded|pending$',
        is_mandatory => 0,
    },
    workflow_id => {
        pattern      => '^\d+$',
        is_mandatory => 0,
    },
    user_id => {
        pattern      => '^\d+$',
        is_mandatory => 0,
    },
    priority => {
        pattern      => '^\d+$',
        is_mandatory => 0,
    },
    creation_date => {
        pattern      => '^.*$',
        is_mandatory => 0,
    },
    creation_time => {
        pattern      => '^.*$',
        is_mandatory => 0,
    },
    hoped_execution_time => {
        pattern      => '^.*$',
        is_mandatory => 0,
    },
    execution_rank => {
        pattern      => '^\d+$',
        is_mandatory => 0,
    },
    label => {
        is_virtual   => 1,
    },
    type => {
        is_virtual   => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        validate => {
            description => 'Validate the operation execution.',
        },
        deny => {
            description => 'Deny the operation execution.',
        }
    };
}


sub new {
    my $class = shift;
    my %args = @_;
    my $self;

    General::checkParams(args     => \%args,
                         required => [ 'priority', 'type' ],
                         optional => { 'workflow_id' => undef,
                                       'params'      => undef });

    # If workflow not defined, initiate a new one with parameters
    if (not defined $args{workflow_id}) {
        my $workflow = Entity::Workflow->new(workflow_name => $args{type});
        $args{workflow_id} = $workflow->id;
    }

    # Compute the execution time if required
    my $hoped_execution_time = defined $args{hoped_execution_time} ? time + $args{hoped_execution_time} : undef;

    # Get the next execution rank within the creation transation.
    $class->beginTransaction;

    eval {
        my $execution_rank = $class->getNextRank(workflow_id => $args{workflow_id});
        my $initial_state  = $execution_rank ? "pending" : "ready";

        $log->debug("Enqueuing new operation <$args{type}>, in workflow <$args{workflow_id}>");

        my $params = {
            operationtype_id     => Operationtype->find(hash => { operationtype_name => $args{type} })->id,
            state                => $initial_state,
            execution_rank       => $execution_rank,
            workflow_id          => $args{workflow_id},
            priority             => $args{priority},
            creation_date        => \"CURRENT_DATE()",
            creation_time        => \"CURRENT_TIME()",
            hoped_execution_time => $hoped_execution_time,
            # The user id will be automatically set by the ORM
            user_id              => undef,
        };

        $self = $class->SUPER::new(%$params);
    };
    if ($@) {
        $log->error($@);
        $class->rollbackTransaction;
    }

    if (defined $args{params}) {
        $self->setParams(params => $args{params});
    }

    $class->commitTransaction;

    return $self;
}

sub label {
    my $self = shift;
    my %args = @_;

    my $type = $self->operationtype;
    return $type->operationtype_label ? $type->operationtype_label : $type->operationtype_name;
}

sub type {
    my $self = shift;

    return $self->operationtype->operationtype_name;
}

sub enqueue {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'priority', 'type' ]);

    return Entity::Operation->new(%args);
}

sub getNextOp {
    my $class = shift;
    my %args = @_;

    my $states = [ "ready", "processing", "prereported", "postreported", "validated" ];
    if ($args{include_blocked}) {
        push @$states, "blocked";
    }

    # Choose the next operation to be treated :
    # if hoped_execution_time is definied, value returned by time function must be superior to hoped_execution_time
    # unless operation is not execute at this moment
    my $operation;
    eval {
        $operation = Entity::Operation->find(
                         hash => {
                             state => { -in => $states },
                             -or   => [ hoped_execution_time => undef, hoped_execution_time => { '<', time } ]
                         },
                         order_by => 'priority asc'
                     );
    };
    if ($@) {
        return;
    }
    return $operation;
}

sub delete {
    my $self = shift;

    # Uncomment this line if we do not want to keep old parameters
    # $self->removePresets();

    # Then create the old_operation from the operation
    OldOperation->new(
        operation_id     => $self->id,
        operationtype_id => $self->operationtype_id,
        workflow_id      => $self->workflow_id,
        user_id          => $self->user_id,
        priority         => $self->priority,
        creation_date    => $self->creation_date,
        creation_time    => $self->creation_time,
        execution_date   => \"CURRENT_DATE()",
        execution_time   => \"CURRENT_TIME()",
        execution_status => $self->state,
        param_preset_id  => $self->param_preset_id,
    );
    $self->SUPER::delete();

    $log->info(ref($self)." <" . $self->id . "> deleted from database (removed from execution list)");
}

sub getWorkflow {
    my $self = shift;
    my %args = @_;

    return $self->workflow;
}


sub setHopedExecutionTime {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['value']);

    my $t = time + $args{value};
    $self->hoped_execution_time($t);
}

sub getNextRank {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'workflow_id' ]);

    my $operation;
    eval {
        $operation = Entity::Operation->find(hash     => { workflow_id => $args{workflow_id} },
                                             order_by => 'execution_rank desc');
    };
    if ($@) {
        $log->debug("No previous operation in queue for workflow $args{workflow_id}");
        return 0;
    }
    my $last_in_db = $operation->execution_rank;
    $log->debug("Previous operation in queue is $last_in_db");
    return $last_in_db + 1;
}

sub setState {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'state' ]);

    $self->setAttr(name => 'state', value => $args{state}, save => 1);
}

sub setParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'params' ]);

    # Firstly get the existing params for this operation
    my $existing_params = $self->getParams;

    my $merge = Hash::Merge->new('RIGHT_PRECEDENT');
    $existing_params = $merge->merge($existing_params, $args{params});

    my $preset = ParamPreset->new(params => $self->buildParams(hash => $existing_params));
    $self->setAttr(name => 'param_preset_id', value => $preset->id, save => 1);
}

sub buildParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'hash' ]);

    PARAMS:
    while(my ($key, $value) = each %{ $args{hash} }) {
        if (not defined $value) { next PARAMS; }

        # Context params must Entity instances, which will be serialized
        # as an entity id, and re-instanciated at pop params.
        if ($key eq 'context') {
            if (ref($value) ne 'HASH') {
                throw Kanopya::Exception::Internal(
                          error => "Params 'context' must be a hash with Entity intances as values."
                      );
            }

            # Serialize each context entities
            CONTEXT:
            while(my ($subkey, $subvalue) = each %{ $value }) {
                # If tag is 'context', this is entities params
                if (not defined $subvalue) {
                    $log->warn("Context value anormally undefined: $subkey");
                    next CONTEXT;
                }
                if (not ($subvalue->isa('Entity') or $subvalue->isa('EEntity'))) {
                    throw Kanopya::Exception::Internal(
                              error => "Can not enqueue operation <$args{type}> with param <$subkey> " .
                                       "of type 'context' that is not an entity."
                          );
                }
                $value->{$subkey} = $subvalue->id;
            }
        }
    }
    return $args{hash};
}

sub getParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, optional => { 'skip_not_found' => 0 });

    my $params = defined $self->param_preset ? $self->param_preset->load() : {};
    if (defined $params->{context}) {
        # Unserialize context entities
        CONTEXT:
        while(my ($key, $value) = each %{ $params->{context} }) {
            # Try to instanciate value as an entity.
            eval {
                $params->{context}->{$key} = EEntity->new(data => Entity->get(id => $value));
            };
            if ($@) {
                # Can skip errors on entity instanciation. Could be usefull when
                # loading context that containing deleted entities.
                if (not $args{skip_not_found}) {
                    $errmsg = "Workflow <" . $self->id .
                              ">, context param <$value>, seems not to be an entity id.\n$@";
                    throw Kanopya::Exception::Internal(error => $errmsg);
                }
                else {
                    delete $params->{context}->{$key};
                    next CONTEXT;
                }
            }
        }
    }
    return $params;
}

sub lockContext {
    my $self = shift;
    my %args = @_;

    $self->beginTransaction;
    eval {
        for my $entity (values %{ $self->getParams->{context} }) {
            $log->debug("Trying to lock entity <$entity>");
            $entity->lock(consumer => $self->getWorkflow);
        }
    };
    if ($@) {
        my $exception = $@;
        $self->rollbackTransaction;
        $exception->rethrow;
    }
    $self->commitTransaction;
}

sub unlockContext {
    my $self = shift;
    my %args = @_;

    # Get the params with option 'skip_not_found', as some input context entities,
    # could be deleted by the operation, so no need to unlock them.
    my $params = $self->getParams(skip_not_found => 1);

    $self->beginTransaction;
    for my $key (keys %{ $params->{context} }) {
        my $entity = $params->{context}->{$key};
        $log->debug("Trying to unlock entity <$key>:" . $entity->id . ">");
        eval {
            $entity->unlock(consumer => $self->getWorkflow);
        };
        if ($@) {
            $log->debug("Unable to unlock context param <$key>\n$@");
        }
    }
    $self->commitTransaction;
}

sub validate {
    my $self = shift;
    my %args = @_;

    $self->setAttr(name => 'state', value => 'validated');
    $self->save();

    $self->removeValidationPerm();
}

sub deny {
    my $self = shift;
    my %args = @_;

    $self->workflow->cancel();

    $self->removeValidationPerm();
}

sub addValidationPerm {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'consumer' ]);

    $self->addPerm(consumer => $args{consumer}, method => 'validate');
    $self->addPerm(consumer => $args{consumer}, method => 'deny');
}

sub removeValidationPerm {
    my $self = shift;
    my %args = @_;

    $self->removePerm(method => 'validate');
    $self->removePerm(method => 'deny');
}


=pod
=begin classdoc

Remove the related param preset from db.

=end classdoc
=cut

sub removePresets {
    my $self  = shift;
    my %args  = @_;

    # Firstly empty the old pattern
    my $presets = $self->param_preset;
    if ($presets) {
        # Detach presets from the policy
        $self->setAttr(name => 'param_preset_id', value => undef, save => 1);

        # Remove the preset
        $presets->remove();
    }
}


1;
