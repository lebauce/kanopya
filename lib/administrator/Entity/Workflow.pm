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

package Entity::Workflow;
use base 'Entity';

use strict;
use warnings;

use Entity::WorkflowDef;
use ParamPreset;
use Kanopya::Exceptions;
use Entity::Operation;

use Data::Dumper;
use Log::Log4perl 'get_logger';

my $log = get_logger("");
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
    related_id => {
        pattern      => '^\d+$',
        is_mandatory => 0,
        is_extended  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        cancel => {
            description => 'Cancel workflow',
            perm_holder => 'entity',
        },
    };
}

sub run {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'name' ], optional => { 'rule' => undef });

    my $def = Entity::WorkflowDef->find(hash => { workflow_def_name => $args{name} });
    my $workflow = Entity::Workflow->new(workflow_name => $args{name}, related_id => $args{related_id});
    delete $args{name};
    delete $args{related_id};

    my @steps = WorkflowStep->search(
                    hash        => { workflow_def_id => $def->id },
                    order_by    => 'workflow_step_id asc'
                );

    my @operationtypes;
    for my $step (@steps) {
        push @operationtypes, $step->operationtype->operationtype_name;
    }

    # If a rule is defined, the workflow is triggered from a rule,
    # So add the rule in the context, and prepend the operation EProcessRule.
    if (defined $args{rule}) {
        $args{params}->{context}->{rule} = $args{rule};

        unshift(@operationtypes, 'ProcessRule');
    }

    # TODO: Use transaction or operation states to not pop operations
    #       while the whole workflow has been enqeued.
    for my $operationtype (@operationtypes) {
        $workflow->enqueue(
            priority => 200,
            type     => $operationtype,
            %args
        );
        if (defined $args{params}) {
            delete $args{params};
        }
    }

    return $workflow;
}

sub enqueue {
    my $self = shift;
    my %args = @_;

    return Entity::Operation->enqueue(
        workflow_id => $self->getAttr(name => 'workflow_id'),
        %args,
    );
}

sub _getOperationsToEnqueue {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { 'operation' => undef, 'workflow' => undef});
    my @operations_to_enqueue = ();

    if (defined $args{workflow}) {
        my $def = Entity::WorkflowDef->find(hash => { workflow_def_name => $args{workflow}->{name} });
        my @steps = WorkflowStep->search(
                        hash        => { workflow_def_id => $def->id },
                        order_by    => 'workflow_step_id asc'
        );
        @operations_to_enqueue = map { {
            priority => 200,
            type     => $_->operationtype->operationtype_name,
        } } @steps;
        # Put params (and context) on the first operation only
        $operations_to_enqueue[0]->{params} = $args{workflow}->{params};
    }
    elsif (defined $args{operation}) {
        push @operations_to_enqueue, $args{operation};
        $operations_to_enqueue[0]->{params} = $args{operation}->{params};
    }

    return @operations_to_enqueue;
}

sub _updatePendingOperationRank {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'offset' ]);

    my @sorted_operations = sort {
        $b->execution_rank <=> $a->execution_rank
    } $self->operations;

    my $incr_num = 0; # num of operations to slide

    for my $operation (@sorted_operations) {
        if ($operation->state eq 'pending') {
            # offset all pending operation to insert new ones
            my $execution_rank = $operation->execution_rank;
            $execution_rank += $args{offset};
            $operation->setAttr(name => 'execution_rank', value => $execution_rank);
            $operation->save();
            $incr_num++;
        }
    }
    return $incr_num;
}

sub _updateProcessingOperationRank {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'offset' ]);

    my $processing_operation = $self->findRelated(
                                filters => ['operations'],
                                hash    => { 'me.state' => ['processing', 'prereported', 'ready'] }
                            );

    my $execution_rank = $processing_operation->execution_rank;
    $execution_rank += $args{offset};
    $processing_operation->setAttr(name => 'execution_rank', value => $execution_rank);
    $processing_operation->save();
    $log->debug('Operation id '.$processing_operation->id.': new rank'.$execution_rank);
}

sub enqueueBefore {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, optional => { 'operation' => undef, 'workflow' => undef});

    my @operations_to_enqueue = $self->_getOperationsToEnqueue(%args);

    my $incr_num = $self->_updatePendingOperationRank( offset => (scalar @operations_to_enqueue) );

    $self->_updateProcessingOperationRank( offset => (scalar @operations_to_enqueue) );

    my $rank_offset = 0;

    for my $operation_to_enqueue (@operations_to_enqueue) {

        my $operation = Entity::Operation->enqueue(
            workflow_id => $self->getAttr(name => 'workflow_id'),
            %$operation_to_enqueue,
        );

        if ($incr_num > 0) {
            # Ajust execution rank
            my $current_rank = $operation->execution_rank;
            my $new_rank = $current_rank - $incr_num - scalar(@operations_to_enqueue) + $rank_offset - 1;
            $operation->setAttr(name => 'execution_rank', value => $new_rank);
            if ($new_rank == 0) {
                $operation->setAttr(name => 'state', value => 'ready');
            }
            $operation->save();
            $rank_offset++;
        }
    }

    map {$log->debug($_->execution_rank.' '.$_->type.' '.$_->state)} $self->operations;
}

sub enqueueNow {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, optional => { 'operation' => undef, 'workflow' => undef});

    my @operations_to_enqueue = $self->_getOperationsToEnqueue(%args);

    my $incr_num = $self->_updatePendingOperationRank( offset => (scalar @operations_to_enqueue) );

    my $rank_offset = 0;

    for my $operation_to_enqueue (@operations_to_enqueue) {

        my $operation = Entity::Operation->enqueue(
            workflow_id => $self->getAttr(name => 'workflow_id'),
            %$operation_to_enqueue,
        );

        if ($incr_num > 0) {
            # Ajust execution rank
            my $current_rank = $operation->execution_rank;
            $operation->setAttr(name => 'execution_rank', value => $current_rank - $incr_num - scalar(@operations_to_enqueue) + $rank_offset);
            $operation->save();
            $rank_offset++;
        }
    }
    map {$log->debug($_->execution_rank.' '.$_->type)} $self->operations;
}

sub getCurrentOperation {
    my ($self, %args) = @_;
    my $adm = Administrator->new();

    my $op;
    eval {
        $op = (Entity::Operation->search(
                  hash     => { workflow_id => $self->id, -not => { state => 'succeeded' } },
                  order_by => 'execution_rank ASC',
              ))[0];
    };
    if ($@ || !defined ($op)) {
        throw Kanopya::Exception::Internal::NotFound(
                  error => "Not more operations within workflow <" . $self->id .  ">"
              );
    }
    return $op;
}

sub cancel {
    my $self = shift;
    my %params;

    Entity::Operation->enqueue(
        priority => 1,
        type     => 'CancelWorkflow',
        params   => {
            workflow_id => $self->id,
        }
    );
}

sub setState {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'state' ]);

    $self->setAttr(name => 'state', value => $args{state});
    $self->save();
}

sub finish {
    my $self = shift;
    my %args = @_;

    my @operations = Entity::Operation->search(hash => {
                         workflow_id => $self->getAttr(name => 'workflow_id'),
                     });

    for my $operation (@operations) {
        $operation->remove();
    }
    $self->setState(state => 'done');
}

1;
