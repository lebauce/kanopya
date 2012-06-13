# WorkflowManager.pm - Object class of Workflow Manager included in Administrator

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
# Created 7 June 2012

package Manager::WorkflowManager;
use base "Manager";

use strict;
use warnings;
use Kanopya::Exceptions;
use General;

use Log::Log4perl "get_logger";
my $log = get_logger("administrator");
use Data::Dumper;

use WorkflowDef;
use WorkflowDefManager;

=head2 checkWorkflowManagerParams

=cut

sub checkWorkflowManagerParams { 
    throw Kanopya::Exception::NotImplemented();
}

=head2 getWorkflowDef
    Return WorkflowDef object
=cut

sub getWorkflowDefs() {
    my ($self,%args) = @_;

    my $manager_id   = $self->getId;
    my @workflow_def = WorkflowDefManager->search (
                            hash => {service_provider_manager_id => $manager_id}
                        );

    return \@workflow_def;
}

=head2 createWorkflow
    Desc: Create a new instance of WorkflowDef. Can be use for initial workflow
    instanciation, but also for workflow definition (with defined specific
    parameters)

    Args: $workflow_name (string), \%workflow_params

    Return: none
=cut

sub createWorkflow { 
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => [ 'workflow_name' ]);

    my $service_provider_id = $self->getServiceProvider()->getAttr(name => 'service_provider_id');
    my $workflow_def_name   = $args{workflow_name};
    my %workflow_def_params;
    my $workflow;
    
    #creation of a new instance of workflow_def
    if (defined $args{workflow_params}) {
        %workflow_def_params = %{$args{workflow_params}};
        $workflow = WorkflowDef->new(workflow_def_name => $workflow_def_name,
                                        params            => \%workflow_def_params
                   );
    } else { 
        $workflow = WorkflowDef->new(workflow_def_name => $workflow_def_name);
    }

    #now associating the new workflow to the manager
    my $workflow_def_id = $workflow->getAttr(name => 'workflow_def_id');
    WorkflowDefManager->new(service_provider_manager_id => $service_provider_id, workflow_def_id => $workflow_def_id);
}

sub instanciateWorkflow { };
sub getSpecificWorkflowParameters { };
sub runWorkflow { };

1;
