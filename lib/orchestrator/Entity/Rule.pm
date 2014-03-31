#    Copyright © 2012-2013 Hedera Technology SAS
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

=pod
=begin classdoc

General Rule class. Implement specific behavior for entity's subscribe method.
Rules are evaluated to be verified (true) or not (false) by the rule engine.
A WorkflowDef can be associated to a rule. When the rule engine dectects that a rule is verified,
it enqueues a Workflow that corresponds to the WorkflowDef.

@since 2012-Dec-17

=end classdoc
=cut

package Entity::Rule;
use base Entity;

use strict;
use warnings;

use Entity::WorkflowDef;
use WorkflowDefRule;
use Hash::Merge;

use TryCatch;
my $err;

use Log::Log4perl "get_logger";
my $log = get_logger("");


use constant ATTR_DEF   => {
    service_provider_id => {
        pattern         => '^.*$',
        is_mandatory    => 1,
        is_editable     => 1,
        is_delegatee    => 1,
        label           => 'Service provider'
    },
    rule_name => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_editable     => 1,
        label           => 'Name'
    },
    formula => {
        pattern         => '^((id\d+)|and|or|not|[ ()!&|])+$',
        is_mandatory    => 1,
        is_editable     => 1,
        description     => "Construct a formula by condition's names with logical operators (and, or, not)." .
                           " It's possible to use parenthesis with spaces between each element of the formula" .
                           ". Press a letter key to obtain the available choice.",
    },
    timestamp => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_editable     => 1,
        label           => 'Timestamp'
    },
    state => {
        pattern         => '^(enabled|disabled|disabled_temp|delayed|triggered)$',
        is_mandatory    => 1,
        is_editable     => 1,
        label           => 'State',
        default         => 'enabled',
    },
    description => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_editable     => 1,
        label           => 'Description'
    },
    formula_string => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_editable     => 1,
    },
    workflow_def => {
        pattern         => '^.*$',
        type            => 'relation',
        relation        => 'single',
        is_virtual      => 1,
        label           => 'Workflow'
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        associateWorkflow => {
            description => 'associate a workflow definition to the rule.',
        },
        deassociateWorkflow => {
            description => 'deassociate a workflow definition to the rule.',
        }
    };
}


my $merge = Hash::Merge->new('LEFT_PRECEDENT');


=pod
=begin classdoc

@constructor

Ensure this class can not be instantiated.

=end classdoc
=cut

sub new {
    my ($class, %args) = @_;

    if ($class eq "Entity::Rule") {
        throw Kanopya::Exception::Internal::AbstractClass();
    }
    return $class->SUPER::new(%args);
}


=pod
=begin classdoc

Fake attr returning the associated service_provider whatever the relation name is.

@return a service_provider instance

=end classdoc
=cut

sub serviceProvider {
    return undef;
}


=pod
=begin classdoc

Fake attr returning the right name for the NotifyWorkflow.

@return String containing a workflow name

=end classdoc
=cut

sub notifyWorkflowName {
    return undef;
}


=pod
=begin classdoc

Virutal attribute that return the first associated workflow definition.

@return the associated workflow definition

=end classdoc
=cut

sub workflowDef {
    my $self = shift;

    try {
        return $self->find(related => "workflow_def_rules")->workflow_def;
    }
    catch ($err) {
        return undef;
    }
}


=pod
=begin classdoc

Associate a workflow definition to the rule by defined specific parameters.

@param workflow_def_id the id of the workflow definition to be associated to the rule

@optional specific_params hashref of specific param to add in addition to origin ones

@return the associated workflow object

=end classdoc
=cut

sub associateWorkflow {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'workflow_def_id' ],
                         optional => { 'specific_params' => {} });

    # Check if the given workflow_def_id belongs to the workflow manager
    # of the service provider of the rule...
    try {
        $self->service_provider->getManager(manager_type => 'WorkflowManager')->find(
            related => "workflow_def_managers",
            hash    => { workflow_def_id => $args{workflow_def_id} }
        );
    }
    catch (Kanopya::Exception::Internal::NotFound $err) {
        throw Kanopya::Exception::Internal::Inconsistency(
                  error => "The workflow definition to associate must belongs to the workflow manager " .
                           "of the service provider of the rule."
              )
    }
    catch ($err) {
        $err->rethrow();
    }

    if (defined $self->workflow_def) {
        $self->deassociateWorkflow();
    }

    # Add an entry to the association class that link a workflow defifition to a rule
    # by specifying specific parameters.
    return WorkflowDefRule->new(rule_id         => $self->id,
                                workflow_def_id => $args{workflow_def_id},
                                param_presets   => { specific => $args{specific_params} });
}


=pod
=begin classdoc

Deassociate a workflowDef from the rule.

=end classdoc
=cut

sub deassociateWorkflow {
    my ($self, %args) = @_;

    my $workflowdef = $self->workflow_def;
    if (defined $workflowdef) {
        # Remove the workflow definition associations
        for my $association ($self->workflow_def_rules) {
            $association->remove();
        }

        # Check if there's subscriptions on this rule
        my @subscriptions = NotificationSubscription->search(hash => { entity_id => $self->id });
        if (@subscriptions > 0) {
            if ($workflowdef->workflow_def_name ne $self->notifyWorkflowName) {
                # If any, must re-associate the rule with the empty workflow
                $self->associateWithNotifyWorkflow();
            }
        }
    }
}


=pod
=begin classdoc

Clone the workflow defintion association if exists and link the clone to the destination rule.
Clone only if both services linked to the rules use the same workflow manager, else log warning.

@param dest_rule The rule to associate with the cloned workflow

=end classdoc
=cut

sub cloneAssociatedWorkflow {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'dest_rule' ]);


    # Check if the service provider of the destination rule has the same workflow manager
    # of the service provider of the current rule.
    try {
        if ($self->service_provider->getManager(manager_type => 'WorkflowManager')->id !=
            $args{dest_rule}->service_provider->getManager(manager_type => 'WorkflowManager')->id) {
            throw Kanopya::Exception::Internal::Inconsistency(
                      error => "The workflow definition to associate must belongs to the workflow manager " .
                               "of the service provider of the rule."
                  );
        }
    }
    catch ($err) {
        $err->rethrow();
    }

    if ($self->workflow_def) {
        # Clone the workflow defition association
        my $association = $self->find(related => "workflow_def_rules");
        return $args{dest_rule}->associateWorkflow(
                   workflow_def_id => $association->workflow_def_id,
                   specific_params => $association->param_presets->{specific}
               );
    }
    else {
        throw Kanopya::Exception::Internal(
                  error => "Can not clone associated workflow definition on a rule " .
                           "that is not asscociated to any workflow definition"
              );
    }
}


=pod
=begin classdoc

Associate a notification workflow to a rule.

=end classdoc
=cut

sub associateWithNotifyWorkflow {
    my $self = shift;

    my $workflow_def;
    try {
        $workflow_def = $self->service_provider->getManager(manager_type => 'WorkflowManager')->find(
                            related => 'workflow_def_managers',
                            hash    => {
                                'workflow_def.workflow_def_name' => $self->notifyWorkflowName
                            }
                        )->workflow_def;
    }
    catch ($err) {
        throw Kanopya::Exception::Internal::Inconsistency(
                  error => "Unable to find the notify workflow definition among the workflow manager " .
                           "of the service provider of the rule,\n$err"
              );
    }
    $self->associateWorkflow(workflow_def_id => $workflow_def->id);
}


=pod
=begin classdoc

Run a workflow the associated to the rule

@optional host_name the node hostname responsible for the rule triggering

@return the corresponding Workflow instance

=end classdoc
=cut

sub triggerWorkflow {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { host_name => undef });

    my $execution_manager;
    try {
        $execution_manager = $self->service_provider->getManager(manager_type => 'ExecutionManager');
    }
    catch ($err) {
        throw Kanopya::Exception::Internal(
                  error => "Service provider <" . $self->service_provider->label .
                           "> has no Execution Manager. Cannot trigger workflow"
              );
    }

    my $association;
    try {
        $association = $self->find(related => "workflow_def_rules");
    }
    catch ($err) {
        throw Kanopya::Exception::Internal(error => "No associated workflow definition to trigger");
    }

    my $wf_manager;
    try {
        $wf_manager = $self->service_provider->getManager(manager_type => 'WorkflowManager');
    }
    catch ($err) {
        throw Kanopya::Exception::Internal(
                  error => "No workflow manager found on the service provider of the rule"
              );
    }

    # Gather the workflow params
    my $all_params = $merge->merge($association->param_presets, $association->workflow_def->param_presets);

    # Replace the undefined automatic params with the defined ones
    $all_params->{automatic} = $wf_manager->_getAutomaticValues(
                                   automatic_params    => $all_params->{automatic} || {},
                                   scope_id            => $all_params->{internal}->{scope_id},
                                   service_provider_id => $self->service_provider_id,
                                   host_name           => $args{host_name},
                               );

    #prepare final workflow params hash
    my $workflow_params = $wf_manager->_defineFinalParams(
                              all_params        => $all_params,
                              workflow_def_name => $association->workflow_def->workflow_def_name,
                              rule_id           => $self->id,
                              sp_id             => $self->service_provider_id,
                          );

    #run the workflow with the fully defined params
    return $execution_manager->run(
               name       => $association->workflow_def->workflow_def_name,
               related_id => $self->service_provider_id,
               params     => $workflow_params,
               rule       => $self,
           );
}


=pod
=begin classdoc

Implement specific behavior for subscription : must associate the rule with an empty workflow when
it is not associated with any.

@return the same value as Entity::subscribe

=end classdoc
=cut

sub subscribe {
    my $self        = shift;
    my %args        = @_;

    my $result  = $self->SUPER::subscribe(%args);

    if (not defined $self->workflow_def) {
        try {
            $self->associateWithNotifyWorkflow();
        }
        catch ($err) {
            $result->remove;
            $err->rethrow();
        }
    }

    return $result;
}


=pod
=begin classdoc

Delete a NotificationsSubscription and deassociate the Notify Workflow of the rule

@param notification_subscription_id the id of
@return the same value as Entity::subscribe

=end classdoc
=cut

sub unsubscribe {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'notification_subscription_id' ]);

    $self->SUPER::unsubscribe(%args);

    if ($self->workflow_def->workflow_def_name eq $self->notifyWorkflowName) {
        if ($self->notification_subscription_entities == 0) {
            $self->deassociateWorkflow();
        }
    }
}


=pod
=begin classdoc

Overridde update method to update formula_string

=end classdoc
=cut

sub update {
    my ($self, %args) = @_;
    my $rep = $self->SUPER::update (%args);
    $self->updateFormulaString();
    return $rep;
}


=pod
=begin classdoc

Overridde delete method to delete possibly linked workflow_def

=end classdoc
=cut

sub delete {
    my $self = shift;

    $self->deassociateWorkflow();
    $self->SUPER::delete();
}


=pod
=begin classdoc

Update formula_string attribute with toString() method value

=end classdoc
=cut

sub updateFormulaString {
    my $self = shift;

    $self->formula_string($self->toString());
}


=pod
=begin classdoc

Find the AggregateConditions ids contained in the rule formula without doublon.

@return array of AggregateConditions ids

=end classdoc
=cut

sub getDependentConditionIds {
    my $self = shift;
    my %ids = map { $_ => undef } ($self->formula =~ m/id(\d+)/g);
    return keys %ids;
}


=pod
=begin classdoc

Return true if there is an active time period for the rule

@return a boolean

=end classdoc
=cut

sub isActive {
    my $self = shift;
    my $active = 0;

    if ($self->entity_time_periods) {
        for my $period ($self->time_periods) {
            $active ||= $period->isActive;
        }
    }
    else {
        $active = 1;
    }

    return $active;
}

1;
