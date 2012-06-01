# Copyright © 2011-2012 Hedera Technology SAS
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

package Workflow;
use base 'BaseDB';

use strict;
use warnings;

use WorkflowDef;
use ParamPreset;
use Kanopya::Exceptions;

use Data::Dumper;
use Log::Log4perl 'get_logger';

my $log = get_logger('administrator');
my $errmsg;

use constant ATTR_DEF => {
    workflow_name => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    state => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub run {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'name' ]);

    my $def = WorkflowDef->find(hash => { workflow_def_name => $args{name} });
    my $workflow = Workflow->new(workflow_name => $args{name});
    delete $args{name};

    my $steps = $def->{_dbix}->workflow_steps;
    while(my $step = $steps->next) {
        $workflow->enqueue(
            priority => 200,
            type     => $step->operationtype->get_column('operationtype_name'),
            %args
        );
        if (defined $args{params}) {
            delete $args{params};
        }
    }
}

sub enqueue {
    my $self = shift;
    my %args = @_;

    Operation->enqueue(
        workflow_id => $self->getAttr(name => 'workflow_id'),
        %args,
    );
}

sub getCurrentOperation {
    my $self = shift;
    my %args = @_;

    my $adm = Administrator->new();

    my $workflow_id = $self->getAttr(name => 'workflow_id');
    my $current = $adm->{db}->resultset('Operation')->search(
                      { workflow_id => $workflow_id, -not => { state => 'succeeded' } },
                      { order_by    => { -asc => 'execution_rank' }}
                  )->single();

    my $op;
    eval {
        $op = Operation->get(id => $current->get_column("operation_id"));
    };
    if ($@) {
        throw Kanopya::Exception::Internal::NotFound(
                  error => "Not more operations within workflow <$workflow_id>"
              );
    }
    return $op;
}

sub cancel {
    my $self = shift;
    my %params;

    Operation->enqueue(
        priority => 1,
        type     => 'CancelWorkflow',
        params   => {
            workflow_id => $self->getAttr(name => 'workflow_id'),
        }
    );
}

sub getParams {
    my $self = shift;
    my %args = @_;

    my %params;
    my $params_rs = $self->{_dbix}->workflow_parameters;
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

sub setParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'params' ]);

    my $param_list = $self->buildParams(hash => $args{params});

    # TODO: Could be smarter
    $self->{_dbix}->workflow_parameters->delete();
    for my $param (@{$param_list}) {
        $self->{_dbix}->workflow_parameters->create($param);
    }
}

sub pepareNextOp {
    my $self = shift;
    my %args = @_;

    $self->getCurrentOperation->setState(state => 'succeeded');

    if(not $args{params}) {
        $args{params} = {};
    }

    # Update the context with the last operation output context
    $args{params}->{context} = $args{context};
    $self->setParams(params => $args{params});

    my $next;
    eval {
        $next = $self->getCurrentOperation();
    };
    if ($@) {
        $self->finish();
    }
    else {
        $next->setState(state => 'ready');
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

sub setState {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'state' ]);

    $self->setAttr(name => 'state', value => $args{state});
    $self->save();
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
            $entity->lock(workflow => $self);
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
    for my $entity (values %{ $params->{context} }) {
        $log->debug("Trying to unlock entity <$entity>");
        eval {
            $entity->unlock(workflow => $self);
        };
        if ($@) {
            $log->debug($@);
        }
    }
    $adm->{db}->txn_commit;
}

sub finish {
    my $self = shift;
    my %args = @_;

    my @operations = Operation->search(hash => {
                         workflow_id => $self->getAttr(name => 'workflow_id'),
                     });

    for my $operation (@operations) {
        $operation->delete();
    }
    $self->setState(state => 'done');
}

1;
