#    Copyright © 2012 Hedera Technology SAS
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

@since 2012-Dec-17

=end classdoc
=cut

package Entity::Rule;
use base "Entity";

use strict;
use warnings;

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

use Entity::WorkflowDef;

use constant ATTR_DEF   => {
    service_provider_id => {
        pattern         => '^.*$',
        is_mandatory    => 1,
        is_extended     => 0,
        is_editable     => 1,
        label           => 'Service provider'
    },
    rule_name => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1,
        label           => 'Name'
    },
    formula => {
        pattern         => '^((id\d+)|and|or|not|[ ()!&|])+$',
        is_mandatory    => 1,
        is_extended     => 0,
        is_editable     => 1,
        description     => "Construct a formula by condition's names with logical operators (and, or, not)."
                           . " It's possible to use parenthesis with spaces between each element of the formula"
                           . ". Press a letter key to obtain the available choice.",
    },
    timestamp => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1,
        label           => 'Timestamp'
    },
    state => {
        pattern         => '(enabled|disabled|disabled_temp|delayed|triggered)$',
        is_mandatory    => 1,
        is_extended     => 0,
        is_editable     => 1,
        label           => 'State'
    },
    workflow_def_id => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1,
        label           => 'Worflow'
    },
    description => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1,
        label           => 'Description'
    },
    formula_string => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods { return { }; }

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

sub associateWithNotifyWorkflow {
    my $self        = shift;

    my $wf_manager  = $self->service_provider->getManager(manager_type => "WorkflowManager");
    # TODO
    # Do not use a fake attribute to retrieve the fake workflow name but create only one
    # fake workflow and modify its scope_id dynamically
    my $wf_name     = $self->notifyWorkflowName;
    my $orig_wf     = Entity::WorkflowDef->find(hash => { workflow_def_name => $wf_name });

    $wf_manager->associateWorkflow(
        new_workflow_name       => $self->id . "_" . $wf_name,
        origin_workflow_def_id  => $orig_wf->id,
        rule_id                 => $self->id
    );
}

=pod
=begin classdoc

Implement specific behavior for subscription : must associate the rule with an empty workflow when it is not associated with any.

@return the same value as Entity::subscribe

=end classdoc
=cut

sub subscribe {
    my $self        = shift;
    my %args        = @_;

    my $result  = $self->SUPER::subscribe(%args);

    if (not defined $self->workflow_def) {
        eval {
            $self->associateWithNotifyWorkflow();
        };
        if ($@) {
            $result->remove;
            $result = undef;
            die $@;
        }
    }

    return $result;
}


sub unsubscribe {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'notification_subscription_id' ]);

    $self->SUPER::unsubscribe(%args);

    # TODO workflow_def_origin should be named workflow_def_origin_id and workflow_def_origin should
    # call directly the WorkflowDef object

    my $wfdef_origin_id = $self->workflow_def->workflow_def_origin;

    if (Entity->get(id => $wfdef_origin_id)->workflow_def_name eq $self->notifyWorkflowName) {
        if ($self->notification_subscription_entities == 0) {
            my $wf_manager  = $self->service_provider->getManager(manager_type => "WorkflowManager");

            $wf_manager->deassociateWorkflow(
                rule_id         => $self->id,
                workflow_def_id => $self->workflow_def->id,
            );
        }
    }
}


=pod
=begin classdoc

Clone the associated workflow if exists and link the clone to the destination rule.
Clone only if both services linked to the rules use the same workflow manager, else log warning.

@param dest_rule The rule to associate with the cloned workflow

=end classdoc
=cut

sub cloneAssociatedWorkflow {
    my ($self, %args) = @_;

    if ($self->workflow_def_id) {
        eval {
            my $src_workflow_manager = ServiceProviderManager->find( hash => {
                 manager_type        => 'WorkflowManager',
                 service_provider_id => $self->service_provider_id,
            });
            my $dest_workflow_manager = ServiceProviderManager->find( hash => {
                manager_type        => 'WorkflowManager',
                service_provider_id => $args{dest_rule}->service_provider_id
            });
            if ($src_workflow_manager->manager_id != $dest_workflow_manager->manager_id) {
                die 'Both linked service providers have not the same workflow manager';
            }
            my $manager = Entity->get(id => $src_workflow_manager->manager_id );
            $manager->cloneWorkflow(
                workflow_def_id => $self->workflow_def_id,
                rule_id         => $args{dest_rule}->id
            );
        };
        if ($@) {
            my $error = $@;
            $log->warn('Can not clone associated workflow : ' . $error);
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
    my $workflow_def = $self->workflow_def;
    $self->SUPER::delete();
    if (defined $workflow_def) { $workflow_def->delete(); };
}

=pod

=begin classdoc

Update formula_string attribute with toString() method value

=end classdoc

=cut

sub updateFormulaString {
    my $self = shift;
    $self->setAttr(name=>'formula_string', value => $self->toString());
    $self->save();
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

1;
