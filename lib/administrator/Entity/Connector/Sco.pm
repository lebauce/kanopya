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

package Entity::Connector::Sco;
use base 'Entity::Connector';
use base 'Manager::WorkflowManager';

use strict;
use warnings;
use General;
use Kanopya::Exceptions;

use ScopeParameter;
use Scope;
use Externalnode;
use Operationtype;
use Workflow;
use WorkflowDef;
use WorkflowDefManager;
use Entity::ServiceProvider::Outside::Externalcluster;

use Data::Dumper;

use Log::Log4perl 'get_logger';
my $log = get_logger('administrator');
my $errmsg;

use constant ATTR_DEF => {};
sub getAttrDef { return ATTR_DEF; }
 
=head2 _prepareParams
    Desc: Retrieve the list of effective parameters desired by the user in the
          final file 

    Args: \%brut_data_params

    Return: \%prepared_data_params 
=cut

sub _prepareParams {
    my ($self,%args) = @_;
    
    General::checkParams(args => \%args, required => [ 'data_params' ]);
    
    my $data_params      = $args{data_params};
    my $template_content = $data_params->{template_content};
    my %prepared_data_params;

    #print Dumper $template_content;
    my @lines            = split (/\n/, $template_content);

    foreach my $line (@lines) {
        my @split = split(/\[\% | \%\]/, $line);
        for (my $i = 1; $i < (scalar @split); $i+=2){
            $prepared_data_params{$split[$i]} = undef;
        }
    }
    #print Dumper \%prepared_data_params;

    return \%prepared_data_params;
}

=head2 createWorkflow
    Desc: override the workflow manager createWorkflow() 
          to add specific workflow step 

    Args: $workflow_name

    Return: created $workflow (object)
=cut

sub createWorkflow {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'workflow_name' ]);

    my $workflow          = $self->SUPER::createWorkflow(%args);
    my $operation_type    = Operationtype->find(
                                hash => {operationtype_name => 'LaunchSCOWorkflow'}
                            );
    my $operation_type_id = $operation_type->getAttr(name => 'operationtype_id');

    #we add a new step to the workflow
    $workflow->addStep(operationtype_id => $operation_type_id);

    return $workflow;
}

=head2 _getAutomaticValues
    Desc: get the values for the workflow's specific params 

    Args: \%automatic_params

    Return: created $workflow (object)
=cut

sub _getAutomaticValues {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'automatic_params', 'scope_id' ]);

    my $automatic_params = $args{automatic_params};

    #get the scope
    my $scope_id            = $args{scope_id};
    my $service_provider_id = $args{service_provider_id};
    my $scope               = Scope->find(hash => { scope_id => $scope_id });
    my $scope_name          = $scope->getAttr(name => 'scope_name');

    if ($scope_name eq 'node') {
        if ((exists $automatic_params->{node_hostname}) && (defined $args{host_name})) {
            $automatic_params->{node_hostname}  = $args{host_name}; 
        } else {
            $errmsg = 'Workflow Manager could not retrieve node hostname';
            $log->error($errmsg);
        }

        if (exists $automatic_params->{ou_from}) {
            eval {
                $automatic_params->{ou_from}  = $self->_getOuFrom(sp_id => $service_provider_id);
            };
            if ($@) {
                $errmsg = 'Error while trying to retrieve ou_from parameter :'.$@;
                $log->error($errmsg);
            }
        }

    } elsif ($scope_name eq 'service_provider') {
        if (exists $automatic_params->{service_provider_name}) {
            eval {
                $automatic_params->{service_provider_name} = $self->_getServiceProviderName(sp_id => $service_provider_id);
            };
            if ($@) {
                $errmsg = 'Error while trying to retrieve service provider name :'.$@;
                $log->error($errmsg);
            }
        }
    }

    return $automatic_params;
}

=head2 _getOuFrom
    Desc: get the origin OU for a node or a set of node 

    Args: $sp_id

    Return: $ou_from
=cut

sub _getOuFrom {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'sp_id' ]);

    my $service_provider            = Entity::ServiceProvider::Outside::Externalcluster->get(id => $args{sp_id});
    my $directory_service_connector = $service_provider->getConnector(
                                          'category' => 'DirectoryService'
                                      );
    my $ou_from                     = $directory_service_connector->getAttr(
                                          name => 'ad_nodes_base_dn'
                                      );

    return $ou_from;
}

=head2 _getServiceProviderName
    Desc: get the name of the service provider that triggered the rule

    Args: $sp_id 

    Return: $sp_name
=cut

sub _getServiceProviderName {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'sp_id' ]);

    my $service_provider = Entity::ServiceProvider->get(id => $args{sp_id});

    my $sp_name          = $service_provider->getAttr(name => 'externalcluster_name');

    return $sp_name;
}

=head2 _defineFinalParams
    Desc: create the final hash for workflow->run() 

    Args: \%all_params, $workflow_name

    Return: \%workflow_params
=cut

sub _defineFinalParams {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'all_params', 'workflow_name', 'rule_id', 'sp_id' ]);

    my $rule_id             = $args{rule_id};
    my $all_params          = $args{all_params};
    my $workflow_name       = $args{workflow_name};
    my $service_provider_id = $args{sp_id};

    #get scope name for operation
    my $scope_id   = $all_params->{internal}->{scope_id};
    my $scope      = Scope->find(hash => { scope_id => $scope_id });
    my $scope_name = $scope->getAttr(name => 'scope_name');

    #merge automatic and specific params in one hash
    my $workflow_values = Hash::Merge::merge($all_params->{automatic}, $all_params->{specific});

    my $workflow_params = { 
        output_directory => $all_params->{internal}->{output_dir},
        output_file      => 'workflow_'.$workflow_name.'_'.time(),
        template_content => $all_params->{data}->{template_content},
        workflow_values  => $workflow_values,
        scope_name       => $scope_name,
        rule_id          => $rule_id,
        sp_id            => $service_provider_id,
    };

    return $workflow_params;
}

1;
