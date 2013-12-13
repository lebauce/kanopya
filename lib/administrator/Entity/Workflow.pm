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

=pod
=begin classdoc

A Workflow, defined by a WorlfowDef instance, is a succession of Operations

=end classdoc
=cut

package Entity::Workflow;
use base 'Entity';

use strict;
use warnings;

use General;
use Entity::WorkflowDef;
use ParamPreset;
use Kanopya::Exceptions;
use Entity::Operation;

use Template;
use Hash::Merge;
use Scalar::Util qw(blessed);
use Clone qw(clone);
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
        default      => 'pending',
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
        },
    };
}


my $template = Template->new();
my $merge    = Hash::Merge->new('RIGHT_PRECEDENT');

=pod
=begin classdoc

Instanciate and run a new workflow from a already defined WorfklowDef

@param name WorfkDef name

@optional rule rule which have triggered the workflow if the workflow is triggered by a rule

@optional related_id Entity related to the workflow

=end classdoc
=cut

sub run {
    my $class = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'name' ],
                         optional => { 'params'     => {},
                                       'rule'       => undef,
                                       'related_id' => undef, });

    my $def = Entity::WorkflowDef->find(hash => { workflow_def_name => $args{name} });

    # Build the workflow description from desc template and params
    my $allparams = clone($args{params}->{params});
    for my $name (keys $args{params}->{context}) {
        if (blessed($args{params}->{context}->{$name})) {
            $allparams->{$name} = $args{params}->{context}->{$name}->label;
        }
    }
    my $description = '';
    my $desctemplate = $def->description;
    $template->process(\$desctemplate, $allparams, \$description);

    # Instanciate the workflow, and add the steps
    my $workflow = Entity::Workflow->new(workflow_name => $description, related_id => $args{related_id});
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


=pod
=begin classdoc

Enqueue an operation in the workflow

@param priority Operation priority
@param type Operation type

@optional params operation parameters
@optional related_id related entity

@return enqueued Operation

=end classdoc
=cut

sub enqueue {
    my ($self, %args) = @_;
    return Entity::Operation->enqueue(workflow_id => $self->id, %args);
}


sub getOperationsParams {
    my $self = shift;

    my @steps = $self->search(related => 'workflow_steps', order_by => 'workflow_step_id asc');
    my @operations_to_enqueue = map { {
        priority => 200,
        type     => $_->operationtype->operationtype_name,
    } } @steps;
    # Put params (and context) on the first operation only
    $operations_to_enqueue[0]->{params} = $self->{params};
    return @operations_to_enqueue;
}

=pod
=begin classdoc

Get list of operation params from a workflow or from an operation

@static

@optional workflow hashref definition : {name   => workflow_def_name,
                                         params => {optional params}};
@optional operation hashref definition : {priority => priority_num,
                                          type     => pperation_name,
                                          params   => {optional params}}

@return arrayref of operations parameters

=end classdoc
=cut

sub _getOperationsToEnqueue {
    my ($class, %args) = @_;
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
    }

    return \@operations_to_enqueue;
}


=pod
=begin classdoc

Shift operations of a workflow of a given offset and from a given rank.

@param offset value of the offset
@param rank rank from which the offset is

@return number of shifted operations

=end classdoc
=cut

sub _updateOperationRankFromGivenRank {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'offset', 'rank' ]);

    my @operations = $self->searchRelated(filters => ['operations'],
                                          order_by => 'execution_rank DESC');

    my $incr_num = 0;
    for my $operation (@operations) {
        # offset all pending operation to insert new ones
        my $execution_rank = $operation->execution_rank;
        if ($execution_rank >= $args{rank}) {
            $operation->execution_rank($execution_rank + $args{offset});
            $incr_num++;
        }
    }

    return $incr_num;
}


=pod
=begin classdoc

Shift pending operations of the workflow of a given offset.

@param offset value of the offset

@return number of shifted operations

=end classdoc
=cut

sub _updatePendingOperationRank {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'offset' ]);

    my @operations = $self->searchRelated(filters => ['operations'],
                                          hash    => { 'me.state' => ['pending'] },
                                          order_by => 'execution_rank DESC');

    for my $operation (@operations) {
        # offset all pending operation to insert new ones
        my $execution_rank = $operation->execution_rank;
        $operation->execution_rank($execution_rank + $args{offset});
    }

    return (scalar @operations);
}


=pod
=begin classdoc

Enqueue a single operation or all the operations of a workflow before the current operation of the workflow

@param current_operation the current operation before which will be enqueud the workflow

@optional workflow hashref definition : {name   => workflow_def_name,
                                         params => {optional params}};
@optional operation hashref definition : {priority => priority_num,
                                          type     => pperation_name,
                                          params   => {optional params}}
@optional operation_state new state of the enqueued operation ('pending' if undefined)
@optional current_operation_state new state of the current operation ('pending' if undefined)

=end classdoc
=cut

sub enqueueBefore {
    my ($self, %args) = @_;
    General::checkParams(args     => \%args,
                         required => [ 'current_operation' ],
                         optional => { 'operation'               => undef,
                                       'workflow'                => undef,
                                       'operation_state'         => 'pending',
                                       'current_operation_state' => 'pending' });

    my $operations_to_enqueue = Entity::Workflow->_getOperationsToEnqueue(%args);

    my $incr_num = $self->_updateOperationRankFromGivenRank(
                       offset => (scalar @$operations_to_enqueue),
                       rank   => $args{current_operation}->execution_rank,
                   );

    my $rank_offset = 0;

    for my $operation_to_enqueue (@$operations_to_enqueue) {
        my $operation = Entity::Operation->enqueue(
            workflow_id => $self->id,
            %$operation_to_enqueue,
        );

        # Ajust execution rank
        my $current_rank = $operation->execution_rank;
        my $new_rank = $current_rank - $incr_num - scalar(@$operations_to_enqueue) + $rank_offset;
        $operation->execution_rank($new_rank);
        $operation->state($args{operation_state});
        $rank_offset++;
    }

    $args{current_operation}->state($args{current_operation_state});

    map {$log->debug($_->execution_rank.' '.$_->type.' '.$_->state)} $self->operations;
}


=pod
=begin classdoc

Enqueue a single operation or all the operations of a workflow
just after the current operation of the workflow

@optional workflow hashref definition : {name   => workflow_def_name,
                                         params => {optional params}};
@optional operation hashref definition : {priority => priority_num,
                                          type     => pperation_name,
                                          params   => {optional params}}

=end classdoc
=cut

sub enqueueNow {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { 'operation' => undef, 'workflow' => undef });

    my $operations_to_enqueue = Entity::Workflow->_getOperationsToEnqueue(%args);

    my $incr_num = $self->_updatePendingOperationRank( offset => (scalar @$operations_to_enqueue) );

    my $rank_offset = 0;
    for my $operation_to_enqueue (@$operations_to_enqueue) {
        my $operation = Entity::Operation->enqueue(workflow_id => $self->id, %$operation_to_enqueue);

        if ($incr_num > 0) {
            # Ajust execution rank
            my $current_rank = $operation->execution_rank;
            $operation->execution_rank($current_rank - $incr_num - scalar(@$operations_to_enqueue) + $rank_offset);
            $rank_offset++;
        }
    }
    map {$log->debug($_->execution_rank.' '.$_->type)} $self->operations;
}


=pod
=begin classdoc

Return first not succeeded operation

@return first not succeeded operation

=end classdoc
=cut

sub getNextOperation {
    my $self = shift;

    my $operation;
    eval {
        $operation = Entity::Operation->find(
                         hash     => { workflow_id => $self->id, -not => { state => 'succeeded' } },
                         order_by => 'execution_rank ASC'
                     );
    };
    if ($@) {
        throw Kanopya::Exception::Internal::NotFound(
                  error => "No more operations within workflow <" . $self->id .  ">"
              );
    }
    return $operation;
}


=pod
=begin classdoc

Prepare parameters and return next operation

@param current current operation

@return next operation

=end classdoc
=cut

sub prepareNextOperation {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'current' ]);

    # Pop the next operation
    my $next = $self->getNextOperation();

    # Avoid infinite workflow, probably due to an internal error
    if ($next->id == $args{current}->id) {
        throw Kanopya::Exception::Internal(
                  error => "Next operation is the same than the current one <" . $next->id .
                           "> in workflow <" . $self->id .  ">"
              );
    }

    if (defined $args{current}->param_preset) {
        if (defined $next->param_preset_id) {
            $args{current}->param_preset->update(params => $next->param_preset->load());
        }
        # Give the current operation params to the next one
        $next->param_preset_id($args{current}->param_preset_id);
    }

    return $next;
}


=pod
=begin classdoc

Cancel workflow

=end classdoc
=cut

sub cancel {
    my $self = shift;

    $self->setState(state => "cancelled");
}


=pod
=begin classdoc

Set workflow state

@param new set value

=end classdoc
=cut

sub setState {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'state' ]);

    $self->setAttr(name => 'state', value => $args{state});
    $self->save();
}


=pod
=begin classdoc

Finish workflow by removing operations and setting state as 'done'

=end classdoc
=cut

sub finish {
    my $self = shift;
    my %args = @_;

    for my $operation ($self->operations) {
        $operation->remove();
    }
    $self->setState(state => 'done');
}


=pod
=begin classdoc

Get related service provider.?
Throw Kanopya::Exception::Internal if related entity is not a service provider

=end classdoc
=cut


sub relatedServiceProvider {
    my $self = shift;

    if (defined $self->related and $self->related->isa('Entity::ServiceProvider')) {
        return $self->related;
    }
    throw Kanopya::Exception::Internal(
          error => "Related entity is not a service provider."
      );
}

1;
