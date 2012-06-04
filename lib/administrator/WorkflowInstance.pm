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

package WorkflowInstance;
use base 'BaseDB';

use strict;
use warnings;

use Kanopya::Exceptions;

use General;
use ScopeParameter;
use Scope;
use WorkflowInstanceParameter;
use Entity::ServiceProvider::Outside;
use Entity::ServiceProvider::Outside::Externalcluster;
use Node;
use Workflow;
use WorkflowDef;
use Entity::Host;
use Data::Dumper;
use Hash::Merge;
use Log::Log4perl 'get_logger';

my $log = get_logger('administrator');
my $errmsg;

use constant ATTR_DEF => {
    workflow_def_id => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    aggregate_rule_id => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    nodemetric_rule_id => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
};

#TODO : XOR Mandatory aggregate_rule_id xor nodemetric_rule_id in new() method
sub getAttrDef { return ATTR_DEF; }

=head2 getWorkflowDef
    Return WorkflowDef object of a WorkflowInstance
=cut

sub getWorkflowDef(){
    my ($self,%args) = @_;
    my $workflow_def_id = $self->getAttr(name => 'workflow_def_id');
    return WorkflowDef->get(id => $workflow_def_id);
}

=head2 getNodesMetrics

    Return automatic and specific values of the workflow instance parameters
    Params:
        scope_id   : scope_id of the workflow instance
        all_params : list of the wanted params
        node_id OR cluster_id : the node id or the cluster id which has launch
        the workflow
=cut

sub getValues {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['scope_id','all_params']);
    #required also node_id and cluster_id

#    if((! defined $args{node_id}) && (! defined $args{cluster_id})){
#        throw Kanopya::Exception(error => "node_id OR cluster_id is missing");
#    }

    my $specific_parameter_values = $self->_getSpecificValues();
    my $automatic_values          = $self->getAutomaticValues(
                                               scope_id => $args{scope_id},
                                               all_params => $args{all_params},
                                               %args,
                                     );
    #Merge the two hash tables
    my $merge = Hash::Merge->new('RIGHT_PRECEDENT');
    my $fusion = $merge->merge($specific_parameter_values, $automatic_values);

    return $fusion;
}


sub setSpecificValues {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => [ 'specific_params']);

    my $specific_params      = $args{specific_params};
    my $workflow_instance_id = $self->getAttr(name => 'workflow_instance_id');

    while (my ($param, $value) = each (%$specific_params)) {
        my $wfparams = {
            workflow_instance_parameter_name  => $param,
            workflow_instance_parameter_value => $value,
            workflow_instance_id              => $workflow_instance_id,
        };
        WorkflowInstanceParameter->new(%$wfparams);
    }
}

sub getScopeParameterNameList {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => [ 'scope_id' ]);

    my @scopeParameterList = ScopeParameter->search(hash=>{scope_id => $args{scope_id}});
    my @array = map {$_->getAttr(name => 'scope_parameter_name')} @scopeParameterList;
    return \@array;
}

sub getSpecificParams {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'scope_id', 'all_params' ]);
    my $all_params = $args{all_params};
    my $scope_id   = $args{scope_id};
    my $scope_parameter_list = $self->getScopeParameterNameList(
        scope_id => $scope_id
    );

    # Remove automatic params
    for my $scope_parameter (@$scope_parameter_list){
        delete $all_params->{$scope_parameter};
    };

    return $all_params;
}

sub _getSpecificValues {
    my ($self,%args) = @_;

    my $workflow_instance_id = $self->getAttr(name => 'workflow_instance_id');

    my @specific_parameter = WorkflowInstanceParameter->search(
        hash => {workflow_instance_id => $workflow_instance_id}
    );

    my $specific_parameter_values;
    my $specific_parameter_name;
    my $specific_parameter_value;

    foreach my $specific_parameter (@specific_parameter) {
        $specific_parameter_name  = $specific_parameter->getAttr (name => 'workflow_instance_parameter_name');
        $specific_parameter_value = $specific_parameter->getAttr (name => 'workflow_instance_parameter_value');
        $specific_parameter_values->{$specific_parameter_name} = $specific_parameter_value;
    }

    return $specific_parameter_values;
}


=head2 _getAutomaticParams

    Return a list (keys of a hash table) of the params whose values are computed by kanopya (i.e. not
    specified by the user).
    Output : {param1 => undef, param2 => undef};
    Params:
        scope_id   : scope_id of the workflow instance
        all_params : list of the wanted params
=cut

sub _getAutomaticParams {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => [ 'scope_id', 'all_params' ]);
    my $all_params = $args{all_params};
    my $scope_id   = $args{scope_id};
    my $scope_parameter_list = $self->getScopeParameterNameList(
        scope_id => $scope_id
    );

    my $automatic_params = {};

    #Hash table creation
    for my $param (@$scope_parameter_list) {
        if (exists $all_params->{$param}){
            $automatic_params->{$param} = undef;
        }
    }

    return $automatic_params;
}

=head2 getAutomaticValues

    Return the list of the values whose values are computed by kanopya (i.e. not
    specified by the user)
    Params:
        scope_id   : scope_id of the workflow instance
        all_params : list of the wanted params
=cut

sub getAutomaticValues {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['scope_id','all_params']);
    # need also node_id cluster_id

    my $automatic_params = $self->_getAutomaticParams(
        scope_id    => $args{scope_id},
        all_params  => $args{all_params},
    );

    delete $args{scope_id};
    delete $args{all_params};


    for my $automatic_param_name (keys %$automatic_params){
        my $param_value = $self->_getAutomaticValue(
                              automatic_param_name => $automatic_param_name,
                              %args,
                          );
        $automatic_params->{$automatic_param_name} = $param_value;
    }

    return $automatic_params;
}


=head2 _getAutomaticValue

    Return the value of a automatic param
    Params:
        automatic_param_name   : the param name
        node_id XOR cluster_id : the related node or cluster id
=cut

sub _getAutomaticValue {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['automatic_param_name']);
    #Required also node_id XOR cluster_id
    if(defined $args{node_id}) {
        return $self->_getAutomaticNodeValue(%args);
    }
    elsif(defined $args{cluster_id}) {
        return $self->_getAutomaticClusterValue(%args);
    }
    else {
        throw Kanopya::Exception(error => "node_id OR cluster_id is missing");
    }
}

=head2 _getAutomaticNodeValue

    Return the value of one of these param : node_id, node_ip, node_name, ou_from
    Params:
        automatic_param_name   : the param name ( node_id, node_ip, node_name, ou_from )
        node_id : the related node id
=cut

sub _getAutomaticNodeValue {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['automatic_param_name','extnode_hostname','service_provider_id']);
    my $automatic_param_name = $args{automatic_param_name};
    my $extnode_hostname        = $args{node_id};
    my $service_provider_id  = $args{service_provider_id};

    if($automatic_param_name eq 'node_hostname') {
        return $extnode_hostname;
    }
    elsif($automatic_param_name eq 'ou_from') {
        my $outside    = Entity::ServiceProvider::Outside
                              ->get('id' => $service_provider_id);
        my $directoryServiceConnector = $outside->getConnector(
                                                      'category' => 'DirectoryService'
                                                  );
        my $ou_from    = $directoryServiceConnector->getAttr(
                                                         'name' => 'ad_nodes_base_dn'
                                                 );
    }
    else{
        throw Kanopya::Exception(error => "Unknown automatic parameter $automatic_param_name in node scope");
    }
}
=head2 _getAutomaticClusterValue

    Return the value of one of these param : cluster_id, cluster_name
    Params:
        automatic_param_name   : the param name ( cluster_id, cluster_name )
        cluster_id : the related cluster id
=cut

sub _getAutomaticClusterValue{
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['automatic_param_name','cluster_id']);
    my $automatic_param_name = $args{automatic_param_name};
    my $cluster_id           = $args{cluster_id};
    if($automatic_param_name eq 'cluster_id'){
        return $cluster_id;
    }
    elsif($automatic_param_name eq 'cluster_name'){
        return  Entity::ServiceProvider::Outside::Externalcluster->get(id => $cluster_id)->getAttr('name' => 'externalcluster_name');
    }
    else{
        throw Kanopya::Exception(error => "Unknown automatic parameter $automatic_param_name in node scope");
    }
}

sub _parse{
    my ($self, %args) = @_;

#   Template specific file may be moved if necessary

    General::checkParams(args => \%args, required => ['tt_file_path']);

    my $tt_file_path = $args{tt_file_path};
    my $scope_parameter_names;
    my $given_params;

    #open workflow template file
    open (my $FILE, "<", $tt_file_path);

    while (my $line = <$FILE>) {
        my @spl = split(/\[\% | \%\]/,$line);

        #stock the parameters in a list
        for(my $i = 1 ; $i < (scalar @spl) ;$i+=2 ){
            $given_params->{$spl[$i]} = undef;
        }
    }
    close ($FILE);

    return $given_params;
}

=head2 _run

    Run the workflow
    Params:
        node_id XOR cluster_id :
=cut

sub _run {
    my ($self, %args) = @_;
    General::checkParams(args => \%args);
#    if((! defined $args{node_id}) && (! defined $args{cluster_id})){
#        throw Kanopya::Exception(error => "node_id OR cluster_id is missing");
#    }

    my $workflow_def_params = $self->getWorkflowDef()->getParamPreset();

    my $template_dir     = $workflow_def_params->{template_dir};
    my $template_file    = $workflow_def_params->{template_file};
    my $output_directory = $workflow_def_params->{output_dir};
    my $scope_id         = $workflow_def_params->{scope_id};

    my $all_params = $self->_parse(tt_file_path => $template_dir.'/'.$template_file);

    my $params_wf     = $self->getValues(
                             all_params => $all_params,
                             scope_id   => $scope_id,
                             %args
                             );

    my $workflow_params     = {
        template_dir     => $template_dir,
        template_file    => $template_file,
        output_directory => $output_directory,
        filename         => 'workflow_'.time(),
        vars             => $params_wf,
    };

    my $workflow_def = $self->getWorkflowDef();
    my $name = $workflow_def->getAttr(name => 'workflow_def_name');

    Workflow->run(name=>$name,params => $workflow_params);
    return $params_wf;
}

=head2 runInstanceFromNodeRuleId

    Run a NodeRule workflow
    Params:
        nodemetric_rule_id
        node_id
=cut

sub runInstanceFromNodeRuleId {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => ['nodemetric_rule_id','node_id']);

    my @workflow_instance_list = WorkflowInstance->search(
                                 hash => {
                                     nodemetric_rule_id => $args{nodemetric_rule_id},
                                 });

    for my $workflow_instance (@workflow_instance_list){
        $workflow_instance->_run('node_id' => $args{node_id});
    }
};

=head2 runInstanceFromClusterRuleId

    Run a ClusterRule workflow
    Params:
        aggregate_rule_id
        cluster_id
=cut

sub runInstanceFromClusterRuleId {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => ['aggregate_rule_id','cluster_id']);

    my @workflow_instance_list = WorkflowInstance->search(
                                 hash => {
                                     aggregate_rule_id => $args{aggregate_rule_id},
                                 });

    for my $workflow_instance (@workflow_instance_list){
        $workflow_instance->_run('cluster_id' => $args{cluster_id});
    }
};
1;
