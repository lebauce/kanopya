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

use Entity::WorkflowDef;

use constant ATTR_DEF   => { };

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

    eval {
        my $wf_manager  = $self->serviceProvider->getManager(manager_type => "workflow_manager");
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
    };
    if ($@) {
        $result->remove;
        $result = undef;
    }

    return $result;
}

1;
