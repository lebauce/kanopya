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

use Data::Dumper;
use Log::Log4perl 'get_logger';

my $log = get_logger('administrator');

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
    my $current = $adm->{db}->resultset('Operation')->search(
                      { workflow_id => $self->getAttr(name => 'workflow_id') },
                      { order_by => { -asc => 'execution_rank' }}
                  )->single();

    return Operation->get(id => $current->get_column("operation_id"));

#    return Operation->find(hash => {
#               workflow_id => $self->getAttr(name => 'workflow_id'),
#               state       => 'processing'
#           });
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
    my %params;

    my $params_rs = $self->{_dbix}->workflow_parameters;
    while (my $param = $params_rs->next){
        if ($param->tag) {
            $params{$param->tag}->{$param->name} = $param->value;
        }
        else {
            $params{$param->name} = $param->value;
        }
    }
    return \%params;
}

sub setParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'params' ]);

    # TODO: Could be smarter
    for my $param (@{$args{params}}) {
        $self->{_dbix}->workflow_parameters->find_or_create($param);
    }
}

sub updateParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'params', 'context' ]);

    my $params_hash = $args{params};
    $params_hash->{context} = $args{context};

    $self->setParams(params => $self->buildParams(hash => $params_hash));
}

sub buildParams {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'hash' ]);

    my $op_params = [];
    while(my ($key, $value) = each %{$args{hash}}) {
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

sub updateState {
    my $self = shift;
    my %args = @_;

    eval {
        Operation->find(hash => {
            workflow_id => $self->getAttr(name => 'workflow_id'),
        });
    };
    if ($@) {
        $self->setState(state => 'done');
    }
}

1;