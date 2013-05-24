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

=pod
=begin classdoc

This module is the operations abstract class.
It defines the operation execution interface to implement in
the concrete operations.

=end classdoc
=cut

package Entity::Operation;
use base Entity;

use strict;
use warnings;

use General;
use Entity::Workflow;
use Operationtype;
use ParamPreset;
use OldOperation;
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
        default      => 'pending',
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


=pod
=begin classdoc

@constructor

Create a new operation from an operation type and a priority.
If params are given in parameters, serialize its in database.

@param type     the operation type
@param priority the execution priority of the operation

@optional params      the operation parameters hash
@optional workflow_id the workflow that the operation belongs to
@optional related_id  the related entity of the workflow

@return the operation instance.

=end classdoc
=cut

sub new {
    my $class = shift;
    my %args = @_;
    my $self;

    General::checkParams(args     => \%args,
                         required => [ 'priority', 'type' ],
                         optional => { 'workflow_id' => undef,
                                       'params'      => undef,
                                       'related_id'  => undef });

    # If workflow not defined, initiate a new one with parameters
    if (not defined $args{workflow_id}) {
        my $workflow = Entity::Workflow->new(workflow_name => $args{type}, related_id => $args{related_id});
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
        $self->serializeParams(params => $args{params});
    }

    $class->commitTransaction;

    return $self;
}


=pod
=begin classdoc

Serialize the params hash in database. All scalar values are jsonifyed,
the entities objects of the context are serialized by there ids.

@param params the params hash to serialize

=end classdoc
=cut

sub serializeParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'params' ]);

    PARAMS:
    while(my ($key, $value) = each %{ $args{params} }) {
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
                    delete $value->{$subkey};
                    next CONTEXT;
                }
                if (not (defined ref ($subvalue) or $subvalue->isa('Entity') or $subvalue->isa('EEntity'))) {
                    throw Kanopya::Exception::Internal(
                              error => "Can not enqueue operation <$args{type}> with param <$subkey> " .
                                       "of type 'context' that is not an entity <$subvalue>."
                          );
                }
                $value->{$subkey} = $subvalue->id;
            }
        }
    }

    # Update the existing presets, create its instead
    if (defined $self->param_preset) {
        $self->param_preset->update(params => $args{params}, override => 1);
    }
    else {
        my $preset = ParamPreset->new(params => $args{params});
        $self->setAttr(name => 'param_preset_id', value => $preset->id, save => 1);
    }
}


=pod
=begin classdoc

Unserialize from database to a params hash. Context entities are instantiated
form there ids.

@optional skip_not_found ignore errors when entities do not exists any more

@return the params hash

=end classdoc
=cut

sub unserializeParams {
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


=pod
=begin classdoc

Globally lock the entities of the context. Insert an entry in Entitylock, if the insert
fail, then a lock is already in db for the entity.

=end classdoc
=cut

sub lockContext {
    my $self = shift;
    my %args = @_;

    $self->beginTransaction;
    eval {
        for my $entity (values %{ $self->unserializeParams->{context} }) {
            $log->debug("Trying to lock entity <$entity>");
            $entity->lock(consumer => $self->workflow);
        }
    };
    if ($@) {
        my $exception = $@;
        $self->rollbackTransaction;
        $exception->rethrow;
    }
    $self->commitTransaction;
}


=pod
=begin classdoc

Remove the possible lock objects related to the entities of the context.

=end classdoc
=cut

sub unlockContext {
    my $self = shift;
    my %args = @_;

    # Get the params with option 'skip_not_found', as some input context entities,
    # could be deleted by the operation, so no need to unlock them.
    my $params = $self->unserializeParams(skip_not_found => 1);

    $self->beginTransaction;
    for my $key (keys %{ $params->{context} }) {
        my $entity = $params->{context}->{$key};
        $log->debug("Trying to unlock entity <$key>:" . $entity->id . ">");
        eval {
            $entity->unlock(consumer => $self->workflow);
        };
        if ($@) {
            $log->debug("Unable to unlock context param <$key>\n$@");
        }
    }
    $self->commitTransaction;
}


=pod
=begin classdoc

Validate the operation that the execution has been stopped because it require validation.

=end classdoc
=cut

sub validate {
    my $self = shift;
    my %args = @_;

    my $executor;
    eval {
        $executor = $self->workflow->relatedServiceProvider->getManager(manager_type => 'ExecutionManager');
    };
    if ($@) {
        my $err = $@;
        if ($@->isa('Kanopya::Exception::Internal')) {
            throw Kanopya::Exception::Internal(
                      error => "Can not validate operation <" . $self->id .
                               "> without related service provider on the workflow."
                  );
        }
        else { $err->rethrow(); }
    }

    # Push a message on the channel 'operation_result' to continue the workflow
    $executor->terminate(operation_id => $self->id, status => 'validated');

    $self->removeValidationPerm();
}


=pod
=begin classdoc

Deny the operation that the execution has been stopped because it require validation.

=end classdoc
=cut

sub deny {
    my $self = shift;
    my %args = @_;

    $self->workflow->cancel();

    $self->removeValidationPerm();
}


=pod
=begin classdoc

Add permissions required by the consumer user to validate/deny the operation.

=end classdoc
=cut

sub addValidationPerm {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'consumer' ]);

    $self->addPerm(consumer => $args{consumer}, method => 'validate');
    $self->addPerm(consumer => $args{consumer}, method => 'deny');
}


=pod
=begin classdoc

Remove permissions required by the consumer user to validate/deny the operation.

=end classdoc
=cut

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

1;
