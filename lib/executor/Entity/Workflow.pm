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
use OperationGroup;
use Kanopya::Exceptions;
use Entity::Operation;
use Entity::Operationtype;
use Kanopya::Database;

use TryCatch;
use Template;
use Hash::Merge;
use Scalar::Util qw(blessed);
use Clone qw(clone);

use Log::Log4perl 'get_logger';
my $log = get_logger("");

use constant ATTR_DEF => {
    workflow_manager_id => {
        label        => 'Workflow manager',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^[0-9\.]*$',
        is_mandatory => 1,
        is_editable  => 0,
    },
    workflow_name => {
        pattern      => '^.*$',
        is_mandatory => 0,
    },
    state => {
        pattern      => '^.*$',
        default      => 'pending',
        is_mandatory => 0,
    },
    user => {
        is_virtual   => 1
    },
    rule => {
        is_virtual   => 1,
        type         => 'relation',
        relation     => 'single'
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

my $merge = Hash::Merge->new('RIGHT_PRECEDENT');


=pod
=begin classdoc

Instanciate and run a new workflow from a already defined WorfklowDef

@param name WorfkDef name
@param workflow_manager the workflow manager component

@optional params the workflow parameters
@optional timeout the number of second to consider the workflow timeouted
@optional rule the rule which have triggered the workflow if the workflow is triggered by a rule
@optional owner_id the user owner of the workflow

=end classdoc
=cut

sub run {
    my ($class, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'name', 'workflow_manager' ],
                         optional => { 'params'   => {},
                                       'timeout'  => undef,
                                       'rule'     => undef,
                                       'owner_id' => Kanopya::Database::currentUser });

    my $def = Entity::WorkflowDef->find(hash => { workflow_def_name => delete $args{name} });

    # Instanciate the workflow, and add the steps
    my $label = $class->formatLabel(params => $args{params}, description => $def->description);

    my $timeout = defined ($args{timeout}) ? (time + $args{timeout}) : undef;
    my $workflow = Entity::Workflow->new(workflow_name    => $label,
                                         workflow_manager => $args{workflow_manager},
                                         owner_id         => delete $args{owner_id},
                                         timeout          => $timeout);

    my @steps = WorkflowStep->search(hash     => { workflow_def_id => $def->id },
                                     order_by => 'workflow_step_id asc');

    my @operationtypes;
    for my $step (@steps) {
        push @operationtypes, $step->operationtype;
    }

    # If a rule is defined, the workflow is triggered from a rule,
    # So add the rule in the context, and prepend the operation EProcessRule.
    if (defined $args{rule}) {
        $args{params}->{context}->{rule} = $args{rule};
        unshift @operationtypes,
            Entity::Operationtype->find(hash => { operationtype_name => 'ProcessRule' });
    }

    my $group = OperationGroup->create();
    for my $operationtype (@operationtypes) {
        $workflow->enqueue(priority => 200, operationtype => $operationtype, group => $group, %args);

        # If some params has been given to the first operation, remove from args
        # to avoid given them to others operation of the workflow.
        delete $args{params};
    }

    return $workflow;
}


=pod
=begin classdoc

Enqueue an operation in the workflow

@param priority Operation priority
@param type Operation type

@optional params operation parameters

@return enqueued Operation

=end classdoc
=cut

sub enqueue {
    my ($self, %args) = @_;

    return Entity::Operation->enqueue(workflow_id => $self->id, %args);
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
                         optional => { 'operation' => undef,
                                       'workflow'  => undef,
                                       'harmless'  => 0,
                                       'operation_state'         => 'pending',
                                       'current_operation_state' => 'pending' });

    my $operations_to_enqueue = Entity::Workflow->_getOperationsToEnqueue(%args);

    Kanopya::Database::beginTransaction;

    my $incr_num = $self->_updateOperationRankFromGivenRank(
                       offset => (scalar @$operations_to_enqueue),
                       rank   => $args{current_operation}->execution_rank,
                   );

    my $rank_offset = 0;
    for my $operation_to_enqueue (@$operations_to_enqueue) {
        my $operation = Entity::Operation->enqueue(workflow_id => $self->id,
                                                   harmless    => $args{harmless},
                                                   %$operation_to_enqueue);

        # Ajust execution rank
        my $current_rank = $operation->execution_rank;
        my $new_rank = $current_rank - $incr_num - scalar(@$operations_to_enqueue) + $rank_offset;
        $operation->execution_rank($new_rank);
        $operation->state($args{operation_state});
        $rank_offset++;
    }

    Kanopya::Database::commitTransaction;

    $args{current_operation}->state($args{current_operation_state});
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

    General::checkParams(args     => \%args,
                         optional => { 'operation' => undef, 'workflow' => undef, 'harmless' => 0 });

    my $operations_to_enqueue = Entity::Workflow->_getOperationsToEnqueue(%args);

    Kanopya::Database::beginTransaction;

    my $incr_num = $self->_updatePendingOperationRank(offset => (scalar @$operations_to_enqueue));

    my $rank_offset = 0;
    for my $operation_to_enqueue (@$operations_to_enqueue) {
        my $operation = Entity::Operation->enqueue(workflow_id => $self->id,
                                                   harmless    => $args{harmless},
                                                   %$operation_to_enqueue);

        if ($incr_num > 0) {
            # Ajust execution rank
            my $current_rank = $operation->execution_rank;
            $operation->execution_rank($current_rank - $incr_num - scalar(@$operations_to_enqueue) + $rank_offset);
            $rank_offset++;
        }
    }

    Kanopya::Database::commitTransaction;

    if (defined $args{operation}) {
        return pop @{ $operations_to_enqueue };
    }
    else {
        return $self;
    }
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
    try {
        $operation = Entity::Operation->find(
                         hash     => {
                             workflow_id => $self->id,
                             -not => {
                                 -or => [ state => 'succeeded',  state => 'failed' ]
                             }
                         },
                         order_by => 'execution_rank ASC'
                     );
    }
    catch (Kanopya::Exception::Internal::NotFound $err) {
        throw Kanopya::Exception::Internal::NotFound(
                  error => "No more operations within workflow <" . $self->id .  ">"
              );
    }
    catch ($err) {
        $err->rethrow();
    }

    return $operation;
}


=pod
=begin classdoc

Compute the next operation rank within the workflow.

=end classdoc
=cut

sub getNextRank {
    my $self = shift;

    my $operation;
    try {
        $operation = $self->find(related => 'operations', order_by => 'execution_rank desc');
    }
    catch ($err) {
        return 0;
    }

    return $operation->execution_rank + 1;
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

    # Duplicate the current operation params for the next operation.
    # It is important to duplicat ethe param perest entry because the operation params
    # must be unmodified to retrieve the orignal params at cancel.
    if (defined $args{current}->param_preset) {
        my $params = $args{current}->param_preset->load();

        # If the next opeartion already have params, merge with the current ones
        if (defined $next->param_preset_id) {
            $next->param_preset->update(
                params   => $merge->merge($params, $next->param_preset->load()),
                override => 1,
            );
        }
        # Else, give the current operation params to the next one
        else {
            $next->param_preset_id(ParamPreset->new(params => $params)->id);
        }
    }

    return $next;
}


=pod
=begin classdoc

Return the operation that has failed in the workflow if exists

=end classdoc
=cut

sub getFailedOperation {
    my $self = shift;

    my $operation;
    try {
        $operation = $self->find(
                         related => 'old_operations',
                         hash     => {
                             -or => [ execution_status => 'cancelled',  execution_status => 'failed' ]
                         },
                         order_by => 'operation_id ASC'
                     );
    }
    catch (Kanopya::Exception::Internal::NotFound $err) {
        return undef;
    }
    catch ($err) {
        $err->rethrow();
    }

    return $operation;
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
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'state' ]);

    $self->state($args{state});
}


=pod
=begin classdoc

Interrpupt the workflow.

=end classdoc
=cut

sub interrupt {
    my ($self, %args) = @_;

    $self->setState(state => 'interrupted');
}


=pod
=begin classdoc

Interrpupt the workflow.

=end classdoc
=cut

sub timeouted {
    my ($self, %args) = @_;

    $log->warn("Worklfow \"" . $self->label . "\" (" . $self->id . ") timeout exceeded..");
    $self->setState(state => 'timeouted');
}


=pod
=begin classdoc

Finish workflow by removing operations and setting state as 'done'

=end classdoc
=cut

sub finish {
    my ($self, %args) = @_;

    for my $operation ($self->operations) {
        $operation->remove();
    }
    $self->setState(state => 'done');
}


=pod
=begin classdoc

Ask to the workflow manager to resume the workflow

=end classdoc
=cut

sub resume {
    my ($self, %args) = @_;

    $self->workflow_manager->resume(workflow_id => $self->id);
}


=pod
=begin classdoc

Build a user friendly label from context params contents, and a template toolkit formated description.

=end classdoc
=cut

sub formatLabel {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'params', 'description' ]);

    my $template = Template->new(General::getTemplateConfiguration());

    # Build the workflow description from desc template and params
    my $allparams = clone($args{params}->{params});
    for my $name (keys %{(defined $args{params}->{context} ? $args{params}->{context} : {})}) {
        if (blessed($args{params}->{context}->{$name})) {
            $allparams->{$name} = $args{params}->{context}->{$name}->label;
        }
    }
    my $label = '';
    my $desctemplate = $args{description};
    $template->process(\$desctemplate, $allparams, \$label);

    return $label;
}


=pod
=begin classdoc

Virtual attribute to get the owner names.

=end classdoc
=cut

sub user {
    my $self = shift;

    my $owner = $self->owner;
    return defined $owner ? $owner->user_firstname . " " . $owner->user_lastname : undef;
}


=pod
=begin classdoc

Virtual attribute to get the possible trigger rule

=end classdoc
=cut

sub rule {
    my $self = shift;

    if ($self->aggregate_rules) {
        my @rules = $self->aggregate_rules;
        return (pop @rules);
    }
    elsif ($self->workflow_noderules) {
        my @noderules = $self->workflow_noderules;
        return (pop @noderules)->nodemetric_rule;
    }
    return undef;
}

sub getOperationsParams {
    my $self = shift;

    my @steps = $self->search(related => 'workflow_steps', order_by => 'workflow_step_id asc');
    my @operations_to_enqueue = map { {
        priority      => 200,
        operationtype => $_->operationtype,
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
        my $group = OperationGroup->create();
        my $def = Entity::WorkflowDef->find(hash => { workflow_def_name => $args{workflow}->{name} });
        my @steps = WorkflowStep->search(hash     => { workflow_def_id => $def->id },
                                         order_by => 'workflow_step_id asc' );

        @operations_to_enqueue = map { {
            priority      => 200,
            group         => $group,
            operationtype => $_->operationtype,
        } } @steps;

        # Put params (and context) on the first operation only
        $operations_to_enqueue[0]->{params} = $args{workflow}->{params};
    }
    elsif (defined $args{operation}) {
        $args{operation}->{operationtype} = Entity::Operationtype->find(hash => {
                                                operationtype_name => delete $args{operation}->{type}
                                            });

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

1;
