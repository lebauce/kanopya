# Operation.pm - Operation class, this is an abstract class

#    Copyright © 2011 Hedera Technology SAS
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
# Created 14 july 2010

=head1 NAME

Operation.pm - Operation class, this is an abstract class

=head1 SYNOPSIS

This Object represent an operation.

=head1 DESCRIPTION


=head1 METHODS

=cut

package Operation;
use base 'BaseDB';

use strict;
use warnings;

use General;
use Workflow;
use ParamPreset;
use Kanopya::Exceptions;

use DateTime;
use Hash::Merge;

use Data::Dumper;
use Log::Log4perl "get_logger";

my $log = get_logger("administrator");
our $VERSION = '1.00';
my $errmsg;

sub enqueue {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'priority', 'type' ]);

#    my $op_rs = $adm->{db}->resultset('Operation')->search(
#                    { type => $args{type},
#                      -or  => $op_params, },
#                    { select   => [ { count => 'operation_parameters.operation_id', -as => 'mycount'} ],
#                      join     => 'operation_parameters',
#                      group_by => 'operation_parameters.operation_id',
#                      having   => { 'mycount' => $nbparams } }
#                );
#
#    my @rows = $op_rs->all;
#    if(scalar(@rows)) {
#        $errmsg = "An operation with exactly same parameters already enqueued !";
#        throw Kanopya::Exception::OperationAlreadyEnqueued(error => $errmsg);
#    }

    return Operation->new(%args);
}

sub new {
    my $class = shift;
    my %args = @_;
    my $self = {};

    General::checkParams(args => \%args, required => [ 'priority', 'type' ]);

    my $adm = Administrator->new();

    # If workflow not defined, initiate a new one with parameters
    if (not defined $args{workflow_id}) {
        my $workflow = Workflow->new();
        $args{workflow_id} = $workflow->getAttr(name => 'workflow_id');
    }
#    else {
#        $workflow = Workflow->get(id => $args{workflow_id})
#    }
#
#    if (defined $args{params}) {
#        $workflow->setParams(params => $args{params});
#    }

    # Compute the execution time if required
    my $hoped_execution_time = defined $args{hoped_execution_time} ? time + $args{hoped_execution_time} : undef;

    # Get the next execution rank within the creation transation.
    $adm->{db}->txn_begin;

    eval {
        my $execution_rank = $class->getNextRank(workflow_id => $args{workflow_id});
        my $initial_state  = $execution_rank ? "pending" : "ready";
        my $user_id        = $adm->{_rightchecker}->{user_id};

        $log->info("Enqueuing new operation <$args{type}>, in workflow <$args{workflow_id}>");

        my $row = {
            type                 => $args{type},
            state                => $initial_state,
            execution_rank       => $execution_rank,
            workflow_id          => $args{workflow_id},
            user_id              => $user_id,
            priority             => $args{priority},
            creation_date        => \"CURRENT_DATE()",
            creation_time        => \"CURRENT_TIME()",
            hoped_execution_time => $hoped_execution_time,
        };

        $self->{_dbix} = $adm->{db}->resultset('Operation')->create($row);
    };
    if ($@) {
        $log->error($@);
        $adm->{db}->txn_rollback;
    }

    bless $self, $class;

    if (defined $args{params}) {
        $self->setParams(params => $args{params});
    }

    $adm->{db}->txn_commit;

    $log->info(ref($self)." saved to database (added in execution list)");

    return $self;
}

=head2 getNextOp

    Class : Public

    Desc : This method return next operation to execute

    Returns the concrete Operation with the execution_rank min

=cut

sub getNextOp {
    my $class = shift;
    my %args = @_;

    my $states = [ "ready", "processing", "prereported", "postreported" ];
    if ($args{include_blocked}) {
        push @$states, "blocked";
    }

    my $adm = Administrator->new();
    # Get all operation
    my $all_ops = $adm->_getDbixFromHash(table => 'Operation', hash => {});
    #$log->debug("Get Operation $all_ops");

    # Choose the next operation to be treated :
    # if hoped_execution_time is definied, value returned by time function must be superior to hoped_execution_time
    # unless operation is not execute at this moment

    my $opdata = $all_ops->search(
        { state => { -in => $states },
          -or   => [ hoped_execution_time => undef, hoped_execution_time => { '<', time } ] },
        { order_by => [ { -asc => 'priority' }, { -asc => 'operation_id' } ]}
    )->next();
    if (! defined $opdata){
        #$log->info("No operation in queue");
        return;
    }
    my $op = Operation->get(id => $opdata->get_column("operation_id"));

    $log->info("Operation execution: ".$op->getAttr(name => 'type'));
    return $op;
}

=head2 delete

    Class : Public

    Desc : This method delete Operation and its parameters

=cut

sub delete {
    my $self = shift;

    my $adm = Administrator->new();

    my $new_old_op = $adm->_newDbix(
        table => 'OldOperation',
        row => {
            type             => $self->getAttr(name => "type"),
            workflow_id      => $self->getAttr(name => "workflow_id"),
            user_id          => $self->getAttr(name => "user_id"),
            priority         => $self->getAttr(name => "priority"),
            creation_date    => $self->getAttr(name => "creation_date"),
            creation_time    => $self->getAttr(name => "creation_time"),
            execution_date   => \"CURRENT_DATE()",
            execution_time   => \"CURRENT_TIME()",
            execution_status => $self->getAttr(name => "state"),
        }
    );
    $new_old_op->insert;

    my $params_rs = $self->{_dbix}->operation_parameters;
    while (my $param = $params_rs->next){
        $new_old_op->create_related('old_operation_parameters', {
            name  => $param->get_column('name'),
            value => $param->get_column('value'),
            tag   => $param->get_column('tag'),
        });
    }

    $params_rs->delete;
    $self->{_dbix}->delete();

    $log->info(ref($self)." deleted from database (removed from execution list)");
}

sub getWorkflow {
    my $self = shift;
    my %args = @_;

    # my $workflow = $self->getRelation(name => 'workflow');
    return Workflow->get(id => $self->getAttr(name => 'workflow_id'));
}

=head setHopedExecutionTime
    modify the field value hoped_execution_time in database
    arg: value : duration in seconds
=cut

sub setHopedExecutionTime {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['value']);

    my $t = time + $args{value};
    $self->{_dbix}->set_column('hoped_execution_time', $t);
    $self->{_dbix}->update;
    $log->debug("hoped_execution_time updated with value : $t");
}

sub getNextRank {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'workflow_id' ]);

    my $adm = Administrator->new();
    my $row = $adm->{db}->resultset('Operation')->search(
                  { workflow_id => $args{workflow_id} },
                  { column   => 'execution_rank',
                    order_by => [ 'execution_rank desc' ]}
              )->first;

    if (! $row) {
        $log->debug("No previous operation in queue for workflow $args{workflow_id}");
        return 0;
    }
    else {
        my $last_in_db = $row->get_column('execution_rank');
        $log->debug("Previous operation in queue is $last_in_db");
        return $last_in_db + 1;
    }
}

sub setState {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'state' ]);

    $self->setAttr(name => 'state', value => $args{state});
    $self->save();
}

sub setParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'params' ]);

    # Firstly get the existing params for this operation
    my $existing_params = $self->getParams;

    my $merge = Hash::Merge->new('RIGHT_PRECEDENT');
    $existing_params = $merge->merge($existing_params, $args{params});

    my $param_list = $self->buildParams(hash => $existing_params);

    # TODO: Could be smarter
    $self->{_dbix}->operation_parameters->delete();
    for my $param (@{$param_list}) {
        $self->{_dbix}->operation_parameters->create($param);
    }
}

sub buildParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'hash' ]);

    my $op_params = [];
    while(my ($key, $value) = each %{$args{hash}}) {
        if (not defined $value) { next; }

        # If value is a hash, this is a set of tagged params
        if (ref($value) eq 'HASH') {
            while(my ($subkey, $subvalue) = each %{$value}) {
                my $param_value;

                # If tag is 'context', this is entities params
                if ($key eq 'context') {
                    if (not defined $subvalue) {
                        $log->warn("Context value anormally undefined: $subkey");
                        next;
                    }

                    if (not ($subvalue->isa('Entity') or $subvalue->isa('EEntity'))) {
                        throw Kanopya::Exception::Internal(
                                  error => "Can not enqueue operation <$args{type}> with param <$subkey> " .
                                           "of type 'context' that is not an entity."
                              );
                    }
                    $param_value = $subvalue->getAttr(name => 'entity_id');
                }
                # If tag is 'preset', this is a composite param, we store it as a ParamPreset
                elsif ($key eq 'presets') {
                    my $preset = ParamPreset->new(name => $subkey, params => $subvalue);
                    $param_value = $preset->getAttr(name => 'param_preset_id');
                }
                else {
                    $param_value = $subvalue;
                }
                push @$op_params, { name => $subkey, value => $param_value, tag => $key};
            }
        }
        else {
             push @$op_params, { name => $key, value => $value };
        }
    }
    return $op_params;
}

sub getParams {
    my $self = shift;
    my %args = @_;

    my %params;
    my $params_rs = $self->{_dbix}->operation_parameters;
    while (my $param = $params_rs->next){
        my $name  = $param->get_column('name');
        my $tag   = $param->get_column('tag');
        my $value = $param->get_column('value');

        if ($tag) {
            if ($tag eq 'context') {
                # Try to instanciate value as an entity.
                eval {
                    $value = EFactory::newEEntity(data => Entity->get(id => $value));
                };
                if ($@) {
                    # Can skip errors on entity instanciation. Could be usefull when
                    # loading context that containing deleted entities.
                    if (not ($@->isa('Kanopya::Exception::DB') and $args{skip_not_found})) {
                        $errmsg = "Workflow <" . $self->getAttr(name => 'workflow_id') .
                                   ">, context param <$value>, seems not to be an entity id.\n$@";
                        $log->debug($errmsg);
                        throw Kanopya::Exception::Internal(error => $errmsg);
                    }
                    else{ next; }
                }
                $params{$tag}->{$name} = $value;
            }
            elsif ($tag eq 'presets') {
                my $preset = ParamPreset->get(id => $value);
                $params{$name} = $preset->load();
            }
            else {
                $params{$tag}->{$name} = $value;
            }
        }
        else {
            $params{$name} = $value;
        }
    }
    return \%params;
}

sub lockContext {
    my $self = shift;
    my %args = @_;

    my $adm = Administrator->new();

    $adm->{db}->txn_begin;
    my $entity;
    eval {
        for $entity (values %{ $self->getParams->{context} }) {
            $log->debug("Trying to lock entity <$entity>");
            $entity->lock(workflow => $self->getWorkflow);
        }
    };
    if ($@) {
        $adm->{db}->txn_rollback;
        throw $@;
    }
    $adm->{db}->txn_commit;
}

sub unlockContext {
    my $self = shift;
    my %args = @_;

    my $adm = Administrator->new();

    # Get the params with option 'skip_not_found', as some input context entities,
    # could be deleted by the operation, so no need to unlock them.
    my $params = $self->getParams(skip_not_found => 1);

    $adm->{db}->txn_begin;
    for my $key (keys %{ $params->{context} }) {
        my $entity = $params->{context}->{$key};
        $log->debug("Trying to unlock entity <$key>:<$entity>");
        eval {
            $entity->unlock(workflow => $self);
        };
        if ($@) {
            $log->debug("Unable to unlock context param <$key>\n$@");
        }
    }
    $adm->{db}->txn_commit;
}

1;
