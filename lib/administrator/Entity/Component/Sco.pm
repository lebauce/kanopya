# Scom.pm - SCOM connector
#    Copyright 2011 Hedera Technology SAS
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
# Created 5 june 2012

=pod
=begin classdoc

Microsoft System Center Orchestrator (SCO) is a workflow management solution.
Kanopya generate a parametrized file to trigger SCO workflows.

=end classdoc
=cut

package Entity::Component::Sco;
use base 'Entity::Component';
use base 'Manager::WorkflowManager';

use strict;
use warnings;

use General;
use Scope;
use Operationtype;
use Entity::Workflow;
use Entity::ServiceProvider;

use Log::Log4perl 'get_logger';
my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {};
sub getAttrDef { return ATTR_DEF; }


=pod
=begin classdoc

Override the workflow manager createWorkflowDef() to add specific workflow step

@param workflow_name

@return created workflow

=end classdoc
=cut

sub createWorkflowDef {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'workflow_name' ]);

    my $workflow = $self->SUPER::createWorkflowDef(%args);

    if (! defined $args{workflow_def_origin}) {
        my $operation_type  = Operationtype->find(
                                  hash => {operationtype_name => 'LaunchSCOWorkflow'}
                              );

        #we add a new step to the workflow
        $workflow->addStep(operationtype_id => $operation_type->id);
    }
    else {
        my @steps = WorkflowStep->search(
            hash => {
                workflow_def_id => $args{workflow_def_origin},
            }
        );
        for my $step (@steps) {
            WorkflowStep->new(
                workflow_def_id  => $workflow->id,
                operationtype_id => $step->operationtype_id,
            );
        }

    }
    return $workflow;
}


=pod
=begin classdoc

Get the values for the workflow's specific params

@param automatic_params

@return created workflow

=end classdoc
=cut

sub _getAutomaticValues {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['automatic_params', 'scope_id'],
                                         optional => {host_name => undef, service_provider_id => undef});

    my $automatic_params = $args{automatic_params};

    #get the scope

    my $scope               = Scope->get(id => $args{scope_id});
    my $scope_name          = $scope->scope_name;

    if ($scope_name eq 'node') {

        if (exists $automatic_params->{node_hostname}) {
            if (defined $args{host_name}) {
                $automatic_params->{node_hostname}  = $args{host_name};
            }
            else {
                $errmsg = 'Workflow Manager could not retrieve node hostname';
                $log->error($errmsg);
            }
        }

        if (exists $automatic_params->{ou_from}) {
            eval {
                $automatic_params->{ou_from} = $self->_getOuFrom(sp_id => $args{service_provider_id});
            };
            if ($@) {
                $errmsg = 'Error while trying to retrieve ou_from parameter :'.$@;
                $log->error($errmsg);
            }
        }
    }
    elsif ($scope_name eq 'service_provider') {
        if (exists $automatic_params->{service_provider_name}) {
            eval {
                # TODO
                # Currently code used only with Externalcluster
                # Code compatible with Entity::ServiceProvider

                my $ext_cluster = Entity::ServiceProvider::Externalcluster->get(id => $args{service_provider_id});
                $automatic_params->{service_provider_name} = $ext_cluster->externalcluster_name;
            };
            if ($@) {
                $errmsg = 'Error while trying to retrieve service provider name :'.$@;
                $log->error($errmsg);
            }
        }
    }

    return $automatic_params;
}


=pod
=begin classdoc

Get the origin OU for a node or a set of node

@param sp_id

@return origin OU

=end classdoc
=cut

sub _getOuFrom {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'sp_id' ]);

    my $service_provider = Entity::ServiceProvider->get(id => $args{sp_id});

    my $directory_service_manager_params = $service_provider->getManagerParameters(
                                               manager_type => 'DirectoryServiceManager'
                                           );

    my $ou_from = $directory_service_manager_params->{ad_nodes_base_dn};

    return $ou_from;
}


=pod
=begin classdoc

Create the final hash for workflow->run()

@param all_params
@param workflow_name
@param rule_id
@param sp_id

@return workflow_params

=end classdoc
=cut

sub _defineFinalParams {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'all_params', 'workflow_def_name',
                                                       'rule_id', 'sp_id' ]);

    my $all_params = $args{all_params};

    #get scope name for operation
    my $scope_id = $all_params->{internal}->{scope_id};
    my $scope    = Scope->get(id => $scope_id);

    #merge automatic and specific params in one hash
    my $workflow_values = Hash::Merge::merge($all_params->{automatic}, $all_params->{specific});

    my $workflow_params = {
        output_directory => $all_params->{internal}->{output_dir},
        output_file      => 'workflow_'.$args{workflow_def_name}.'_'.time(),
        template_content => $all_params->{data}->{template_content},
        workflow_values  => $workflow_values,
        scope_name       => $scope->scope_name,
        rule_id          => $args{rule_id},
        sp_id            => $args{sp_id},
    };

    return $workflow_params;
}

1;
