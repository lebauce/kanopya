# EternalCluster.pm - This object allows to manipulate external cluster configuration
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
# Created 3 july 2010
package Entity::ServiceProvider::Outside::Externalcluster;
use base 'Entity::ServiceProvider::Outside';

use strict;
use warnings;

use Kanopya::Exceptions;
use Administrator;
use General;

use AggregateCombination;
use AggregateCondition;
use AggregateRule;
use Clustermetric;
use ScomIndicator;


use Log::Log4perl "get_logger";
use Data::Dumper;

our $VERSION = "1.00";

my $log = get_logger("administrator");
my $errmsg;
use constant ATTR_DEF => {
    externalcluster_name    =>  {pattern        => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 0},
    externalcluster_desc    =>  {pattern        => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
    externalcluster_state   => {pattern         => '^.*$',
                                is_mandatory    => 0,
                                is_extended     => 0,
                                is_editable        => 0},
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        'create'    => {'description' => 'create a new cluster',
                        'perm_holder' => 'mastergroup',
        },
        'get'        => {'description' => 'view this cluster',
                        'perm_holder' => 'entity',
        },
        'update'    => {'description' => 'save changes applied on this cluster',
                        'perm_holder' => 'entity',
        },
        'remove'    => {'description' => 'delete this cluster',
                        'perm_holder' => 'entity',
        },
        'setperm'    => {'description' => 'set permissions on this cluster',
                        'perm_holder' => 'entity',
        },
    };
}

sub toString() {
    my $self = shift;
    return 'External Cluster ' . $self->getAttr( name => 'externalcluster_name');
}

=head2 getState

=cut

sub getState {
    my $self = shift;
    my $state = $self->{_dbix}->get_column('externalcluster_state');
    return wantarray ? split(/:/, $state) : $state;
}

=head2 setState

=cut

sub setState {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['state']);
    my $new_state = $args{state};
    my $current_state = $self->getState();
    $self->{_dbix}->update({'externalcluster_prev_state' => $current_state,
                            'externalcluster_state' => $new_state.":".time})->discard_changes();
}


=head2 addNode

Not supposed to be used (or for test purpose).
Externalcluster nodes are updated using appropriate connector
See updateNodes()

=cut

sub addNode {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['hostname']);

    $self->{_dbix}->parent->externalnodes->create({
        externalnode_hostname   => $args{hostname},
        externalnode_state      => 'down',
    });
}

sub getNode {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['externalnode_id']);
    my $repNode;
    my $node = $self->{_dbix}->parent->externalnodes->find({
        externalnode_id   => $args{externalnode_id},
    });
    $repNode->{hostname} = $node->get_column('externalnode_hostname');
    return $repNode;
}

sub getNodeState {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['hostname']);
    my $repNode;
    my $node = $self->{_dbix}->parent->externalnodes->find({
        externalnode_hostname   => $args{hostname},
    });
    
    return $node->get_column('externalnode_state');
}

sub getNodeId {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['hostname']);
    my $repNode;
    my $node = $self->{_dbix}->parent->externalnodes->find({
        externalnode_hostname   => $args{hostname},
    });
    
    return $node->get_column('externalnode_id');
}

sub updateNodeState {
    my $self = shift;
    my %args = @_;
    
     $self->{_dbix}->parent->externalnodes->update_or_create({
                externalnode_hostname   => $args{hostname},
                externalnode_state      => $args{state},
            });
}


sub getDisabledNodes {
    my ($self, %args) = @_;
    
    my $shortname = defined $args{shortname};
    
    my $node_rs = $self->{_dbix}->parent->externalnodes;
    
    my $domain_name;
    my @nodes;
    while (my $node_row = $node_rs->next) {
        if($node_row->get_column('externalnode_state') eq 'disabled'){
            my $hostname = $node_row->get_column('externalnode_hostname');
            $hostname =~ s/\..*// if ($shortname);
            push @nodes, {
                hostname           => $hostname,
                state              => $node_row->get_column('externalnode_state'),
                id                 => $node_row->get_column('externalnode_id'),
                num_verified_rules => $node_row->verified_noderules
                                               ->search({
                                                 verified_noderule_state => 'verified'})
                                               ->count(),
                num_undef_rules    => $node_row->verified_noderules
                                               ->search({
                                                 verified_noderule_state => 'undef'})
                                               ->count(),
            };
        }
    }

    return \@nodes;
}
sub getNodes {
    my ($self, %args) = @_;
    
    my $shortname = defined $args{shortname};
    
    my $node_rs = $self->{_dbix}->parent->externalnodes;
    
    my $domain_name;
    my @nodes;
    while (my $node_row = $node_rs->next) {
        if($node_row->get_column('externalnode_state') ne 'disabled'){
            my $hostname = $node_row->get_column('externalnode_hostname');
            $hostname =~ s/\..*// if ($shortname);
            push @nodes, {
                hostname           => $hostname,
                state              => $node_row->get_column('externalnode_state'),
                id                 => $node_row->get_column('externalnode_id'),
                num_verified_rules => $node_row->verified_noderules
                                               ->search({
                                                 verified_noderule_state => 'verified'})
                                               ->count(),
                num_undef_rules    => $node_row->verified_noderules
                                               ->search({
                                                 verified_noderule_state => 'undef'})
                                               ->count(),
            };
        }
    }

    return \@nodes;
}

=head2 updateNodes

    Update external nodes list using the linked DirectoryService connector

=cut

sub updateNodes {
     my $self = shift;
     my %args = @_;
     
     my $ds_connector = $self->getConnector( category => 'DirectoryService' );
     my $nodes = $ds_connector->getNodes(%args);
     
     my @created_nodes;
     
     my $new_node_count = 0;
     for my $node (@$nodes) {
         if (defined $node->{hostname}) {
            $new_node_count++;
            
            my $row = $self->{_dbix}->parent->externalnodes->find({
                externalnode_hostname   => $node->{hostname},
            });
            
            if(! defined $row){
                my $node_row = $self->{_dbix}->parent->externalnodes->create({
                    externalnode_hostname   => $node->{hostname},
                    externalnode_state      => 'down',
                });
                $node->{id} =  $node_row->id;
                push @created_nodes, $node;
            }
         }
     }
     
     return {created_nodes => \@created_nodes, node_count => $new_node_count};
     # TODO remove dead nodes from db
}

sub getIndicatorsIds {
    my ($self, %args) = @_;

    my @indicators = ScomIndicator->search (
        hash => {
            service_provider_id => 65
        }
    );
    my @indicators_ids;
    my $indicator_id;

    foreach my $indicator (@indicators) {
        $indicator_id = $indicator->getAttr( name => 'scom_indicator_id' );
        push @indicators_ids, $indicator_id;
    }

    return \@indicators_ids;
}

sub getIndicatorOidFromId {
    my ($self, %args) = @_;

     General::checkParams(args => \%args, required => ['indicator_id']);

    my $indicator_id    = $args{indicator_id};
    my $indicator       = ScomIndicator->find (
        hash => {
            scom_indicator_id => $indicator_id, service_provider_id => 65
        }
    );
    my $indicator_oid   = $indicator->getAttr(name => 'scom_indicator_oid');

    return $indicator_oid;
}

=head2 getNodesMetrics

    Retrieve cluster nodes metrics values using the linked MonitoringService connector
    
    Params:
        indicators : array ref of indicator name (eg 'ObjectName/CounterName')
        time_span  : number of last seconds to consider when compute average on metric values
        <optional> shortname : bool : node identified by their fqn or hostname in resulting struct
=cut

sub getNodesMetrics {
     my $self = shift;
     my %args = @_;

     General::checkParams(args => \%args, required => ['indicators', 'time_span']);
     
     my $shortname = defined $args{shortname};
     
     my $ms_connector = $self->getConnector( category => 'MonitoringService' );
     my $nodes = $self->getNodes();
     
     my @hostnames = map { $_->{hostname} } @$nodes;
     
     my $data = $ms_connector->retrieveData(
        nodes => \@hostnames,
        %args,
     );

    if ($shortname) {
        my %data_shortnodename;
        while (my ($nodename, $metrics) = each %$data) {
             $nodename =~ s/\..*//;
             $data_shortnodename{$nodename} = $metrics;
        }
        return \%data_shortnodename;
    }
    return $data;
}


sub generateClustermetricAndCombination{
    my ($self,%args) = @_;
    my $extcluster_id = $args{extcluster_id};
    my $indicator     = $args{indicator};
    my $func          = $args{func};
    
    my $cm_params = {
        clustermetric_service_provider_id      => $extcluster_id,
        clustermetric_indicator_id             => $indicator->{id},
        clustermetric_statistics_function_name => $func,
        clustermetric_window_time              => '1200',
    };
    my $cm = Clustermetric->new(%$cm_params);
   
    my $acf_params = {
        aggregate_combination_service_provider_id   => $extcluster_id,
        aggregate_combination_formula               => 'id'.($cm->getAttr(name => 'clustermetric_id'))
    };
    my $aggregate_combination = AggregateCombination->new(%$acf_params);
    my $rep = {
        cm_id => $cm->getAttr(name => 'clustermetric_id'),
        comb_id => $aggregate_combination->getAttr(name => 'aggregate_combination_id'),
    };
    return $rep;
}


=head2 monitoringDefaultInit

    Insert some basic clustermetrics, combinations and rules for this cluster

    Use SCOM indicators by default
    TODO : more generic (unhardcode SCOM, metrics depend on monitoring service)

=cut

sub monitoringDefaultInit {
    my $self = shift;

    my $adm = Administrator->new();
    
    my $scom_indicatorset = $adm->{'manager'}{'monitor'}->getSetDesc( set_name => 'scom' );
    my $active_session_indicator_id; 
    my @indicators;
    
    my ($low_mean_cond_mem_id, $low_mean_cond_cpu_id, $low_mean_cond_net_id);
    
    my @funcs = qw(mean max min std dataOut);
    
    foreach my $indicator (@{$scom_indicatorset->{ds}}){
        if($indicator->{oid} eq 'Terminal Services/Active Sessions'){
            $active_session_indicator_id = $indicator->{id};
        }
        push @indicators, $indicator->{id};
    }

    my $extcluster_id = $self->getAttr( name => 'outside_id' );
    
    foreach my $indicator (@{$scom_indicatorset->{ds}}) {
        $self->generateNodeMetricRules(
            indicator_id  => $indicator->{id},
            indicator_oid => $indicator->{oid},
            extcluster_id => $extcluster_id,
        );
        
     if (
        0 == grep {$indicator->{oid} eq $_} ('Memory/PercentMemoryUsed','Processor/% Processor Time','Network Adapter/PercentBandwidthUsedTotal','LogicalDisk/% Free Space')
        ){
            foreach my $func (@funcs) {
                    my $ids = $self->generateClustermetricAndCombination(
                        extcluster_id => $extcluster_id,
                        indicator     => $indicator,
                        func          => $func,
                    );
            }
        }elsif($indicator->{oid} eq 'Memory/PercentMemoryUsed'){
            $low_mean_cond_mem_id = $self->ruleGeneration(indicator => $indicator, extcluster_id => $extcluster_id, label => 'Memory');
        }elsif($indicator->{oid} eq 'Processor/% Processor Time'){
            $low_mean_cond_cpu_id = $self->ruleGeneration(indicator => $indicator, extcluster_id => $extcluster_id, label => 'Processor');
        }elsif($indicator->{oid} eq 'Network Adapter/PercentBandwidthUsedTotal'){
            $low_mean_cond_net_id = $self->ruleGeneration(indicator => $indicator, extcluster_id => $extcluster_id, label => 'Network');
        }
    }
    
    
   my $params_rule = {
        aggregate_rule_service_provider_id  => $extcluster_id,
        aggregate_rule_formula              => 'id'.$low_mean_cond_mem_id.'&&'.'id'.$low_mean_cond_cpu_id.'&&'.'id'.$low_mean_cond_net_id,
        aggregate_rule_state                => 'enabled',
#        aggregate_rule_action_id            => 0,
        aggregate_rule_label                => 'Cluster load',
        aggregate_rule_description          => 'Mem, cpu and network usages are low, your cluster may be oversized',
    };
    my $combo_rule = AggregateRule->new(%$params_rule);
    
        #SPECIAL TAKE SUM OF SESSION ID
    my $cm_params = {
        clustermetric_service_provider_id      => $extcluster_id,
        clustermetric_indicator_id             => $active_session_indicator_id,
        clustermetric_statistics_function_name => 'sum',
        clustermetric_window_time              => '1200',
    };
    my $cm = Clustermetric->new(%$cm_params);
    
    my $acf_params = {
        aggregate_combination_service_provider_id   => $extcluster_id,
        aggregate_combination_formula               => 'id'.($cm->getAttr(name => 'clustermetric_id'))
    };
    my $aggregate_combination = AggregateCombination->new(%$acf_params);
}

sub ruleGeneration{
    my ($self,%args) = @_;
    my $indicator = $args{indicator};
    my $extcluster_id = $args{extcluster_id};
    my $label         = $args{label};
    my $inverse       = $args{inverse};
    
    my @funcs = qw(max min);
    foreach my $func (@funcs) {
            my $ids = $self->generateClustermetricAndCombination(
                extcluster_id => $extcluster_id,
                indicator     => $indicator,
                func          => $func,
            );
    }
    
    my $mean_ids = $self->generateClustermetricAndCombination(
        extcluster_id => $extcluster_id,
        indicator     => $indicator,
        func          => 'mean',
    );
    my $std_ids = $self->generateClustermetricAndCombination(
        extcluster_id => $extcluster_id,
        indicator     => $indicator,
        func          => 'std',
    );
    
    my $out_ids = $self->generateClustermetricAndCombination(
        extcluster_id => $extcluster_id,
        indicator     => $indicator,
        func          => 'dataOut',
    );
    
    my $combination_params = {
        aggregate_combination_service_provider_id => $extcluster_id,
        aggregate_combination_formula             => 'id'.($std_ids->{cm_id}).'/ id'.($mean_ids->{cm_id}),
    };
    
    my $coef_comb = AggregateCombination->new(%$combination_params);
    
   my $condition_params = {
        aggregate_condition_service_provider_id => $extcluster_id,
        aggregate_combination_id                => $coef_comb->getAttr(name=>'aggregate_combination_id'),
        comparator                              => '>',
        threshold                               => 0.2,
        state                                   => 'enabled',
    };
     
   my $coef_cond = AggregateCondition->new(%$condition_params);
   my $coef_cond_id = $coef_cond->getAttr(name => 'aggregate_condition_id');

   $condition_params = {
        aggregate_condition_service_provider_id => $extcluster_id,
        aggregate_combination_id                => $std_ids->{comb_id},
        comparator                              => '>',
        threshold                               => 10,
        state                                   => 'enabled',
    };
     
   my $std_cond = AggregateCondition->new(%$condition_params);
   my $std_cond_id = $std_cond->getAttr(name => 'aggregate_condition_id'); 

   $condition_params = {
        aggregate_condition_service_provider_id => $extcluster_id,
        aggregate_combination_id                => $out_ids->{comb_id},
        comparator                              => '>',
        threshold                               => 0,
        state                                   => 'enabled',
    };
     
   my $out_cond = AggregateCondition->new(%$condition_params);
   my $out_cond_id = $out_cond->getAttr(name => 'aggregate_condition_id');
   
   my $params_rule = {
        aggregate_rule_service_provider_id  => $extcluster_id,
        aggregate_rule_formula              => 'id'.$coef_cond_id.' && '.'id'.$std_cond_id,
        aggregate_rule_state                => 'enabled',
#        aggregate_rule_action_id            => 0,
        aggregate_rule_label                => 'Cluster '.$label.' homogeneity',
        aggregate_rule_description          => $label.' is not well balanced across the cluster',
    };
    my $homo_rule = AggregateRule->new(%$params_rule);
    
   $params_rule = {
        aggregate_rule_service_provider_id  => $extcluster_id,
        aggregate_rule_formula              => 'id'.$out_cond_id,
        aggregate_rule_state                => 'enabled',
#        aggregate_rule_action_id            => 0,
        aggregate_rule_label                => 'Cluster '.$label.' consistency',
        aggregate_rule_description          => 'The '.$label.' usage of some nodes of the cluster is far from the average behavior',
    };
    my $out_rule = AggregateRule->new(%$params_rule);
    
   $condition_params = {
        aggregate_condition_service_provider_id => $extcluster_id,
        aggregate_combination_id                => $mean_ids->{comb_id},
        comparator                              => '>',
        threshold                               => 80,
        state                                   => 'enabled',
    };
     
   my $mean_cond = AggregateCondition->new(%$condition_params);
   my $mean_cond_id = $mean_cond->getAttr(name => 'aggregate_condition_id');
   $params_rule = {
        aggregate_rule_service_provider_id  => $extcluster_id,
        aggregate_rule_formula              => 'id'.$mean_cond_id,
        aggregate_rule_state                => 'enabled',
#        aggregate_rule_action_id            => 0,
        aggregate_rule_label                => 'Cluster '.$label.' overload',
        aggregate_rule_description          => 'Average '.$label.' is too high, your cluster may be undersized',
    };
    my $mean_rule = AggregateRule->new(%$params_rule);
    
   $condition_params = {
        aggregate_condition_service_provider_id => $extcluster_id,
        aggregate_combination_id                => $mean_ids->{comb_id},
        comparator                              => '<',
        threshold                               => 10,
        state                                   => 'enabled',
    };
     
   my $low_mean_cond = AggregateCondition->new(%$condition_params);
    
   return $low_mean_cond->getAttr(name => 'aggregate_condition_id');
}
#        
#
#            if (
#               ($indicator->{oid} eq 'Memory/PercentMemoryUsed')   || 
#               ($indicator->{oid} eq 'Processor/% Processor Time') ||
#               ($indicator->{oid} eq 'Network Adapter/PercentBandwidthUsedTotal')
#            ){
#
#             }elsif($indicator->{oid} eq 'LogicalDisk/% Free Space'){
#                my $ids = $self->generateClustermetricAndCombination(
#                    extcluster_id => $extcluster_id,
#                    indicator     => $indicator,
#                    func          => $func,
#                );
#            }
#            else{
#                $self->generateClustermetricAndCombination(
#                    extcluster_id => $extcluster_id,
#                    indicator     => $indicator,
#                    func          => $func,
#                );
#            }
#        }
#        

#    } #ALL CLUSTERMETRIC AND THEIR CORRESPONDING IDENTITY ARE NOW CREATED
#    
#    
#    #THEN CREATE CONDITIONS AND RULES
#    foreach my $ndoor_comb_id (@ndoor_comb_ids){
#        $self->generateAOutOfRangeRule(
#            ndoor_comb_id => $ndoor_comb_id,
#            extcluster_id => $extcluster_id,
#        )
#    }
#    foreach my $i (0..(scalar @std_cm_ids)-1){
#        $self->generateCoefficientOfVariationRules(
#            id_std        => $std_cm_ids[$i],
#            id_mean       => $mean_cm_ids[$i],
#            extcluster_id => $extcluster_id,
#        )
#    }
#    
#    foreach my $mean_percent_comb_id (@mean_over_comb_ids){
#        $self->generateOverRules(
#            mean_percent_comb_id => $mean_percent_comb_id,
#            extcluster_id        => $extcluster_id,
#        )
#    }
#    
#    foreach my $mean_percent_comb_id (@mean_under_comb_ids){
#        $self->generateUnderRules(
#            mean_percent_comb_id => $mean_percent_comb_id,
#            extcluster_id        => $extcluster_id,
#        )
#    }
#}



# CHECK IF THERE ARE DATA OUT OF MEAN - x SIGMA RANGE
sub generateAOutOfRangeRule {
    my ($self,%args) = @_;
    my $ndoor_comb_id            = $args{ndoor_comb_id};
    my $extcluster_id            = $args{extcluster_id};
        
    my $condition_params = {
        aggregate_condition_service_provider_id => $extcluster_id,
        aggregate_combination_id                => $ndoor_comb_id,
        comparator                              => '>',
        threshold                               => 0,
        state                                   => 'enabled',
    };
     
    my $aggregate_condition = AggregateCondition->new(%$condition_params);
    my $label = 'Isolated data - '.$aggregate_condition->getCombination()->toString();
   
    my $params_rule = {
        aggregate_rule_service_provider_id  => $extcluster_id,
        aggregate_rule_formula              => 'id'.($aggregate_condition->getAttr(name => 'aggregate_condition_id')),
        aggregate_rule_state                => 'enabled',
#        aggregate_rule_action_id            => 0,
        aggregate_rule_label                => $label,
        aggregate_rule_description          => 'Check the indicators of the nodes generating isolated datas',
    };
    my $aggregate_rule = AggregateRule->new(%$params_rule);
};

sub generateOverRules {
    my ($self,%args) = @_;
    my $mean_percent_comb_id     = $args{mean_percent_comb_id};
    my $extcluster_id            = $args{extcluster_id};
        
    my $condition_params = {
        aggregate_condition_service_provider_id => $extcluster_id,
        aggregate_combination_id                => $mean_percent_comb_id,
        state                                   => 'enabled',
    };
   
   $condition_params->{comparator} = '>';
   $condition_params->{threshold}  = 70;
   
   my $aggregate_condition = AggregateCondition->new(%$condition_params);
    
   my $params_rule = {
        aggregate_rule_service_provider_id  => $extcluster_id,
        aggregate_rule_formula              => 'id'.($aggregate_condition->getAttr(name => 'aggregate_condition_id')),
        aggregate_rule_state                => 'enabled',
#        aggregate_rule_action_id            => 0,
    };
    
    $params_rule->{aggregate_rule_label}       = 'Cluster '.$aggregate_condition->getCombination()->toString().' overloaded';
    $params_rule->{aggregate_rule_description} = 'You may add a node';
    
    my $aggregate_rule = AggregateRule->new(%$params_rule);
};


sub generateUnderRules {
    my ($self,%args) = @_;
    my $mean_percent_comb_id     = $args{mean_percent_comb_id};
    my $extcluster_id            = $args{extcluster_id};
        
    my $condition_params = {
        aggregate_condition_service_provider_id => $extcluster_id,
        aggregate_combination_id                => $mean_percent_comb_id,
        state                                   => 'enabled',
    };
   
   $condition_params->{comparator} = '<';
   $condition_params->{threshold}  = 10;
   
   my $aggregate_condition = AggregateCondition->new(%$condition_params);
    
   my $params_rule = {
        aggregate_rule_service_provider_id  => $extcluster_id,
        aggregate_rule_formula              => 'id'.($aggregate_condition->getAttr(name => 'aggregate_condition_id')),
        aggregate_rule_state                => 'enabled',
#        aggregate_rule_action_id            => 0,
    };
    
    $params_rule->{aggregate_rule_label}       = 'Cluster '.$aggregate_condition->getCombination()->toString().' underloaded';
    $params_rule->{aggregate_rule_description} = 'You may add a node';
    
    my $aggregate_rule = AggregateRule->new(%$params_rule);
};

# CHECK IF THERE ARE DATA OUT OF MEAN - x SIGMA RANGE
sub generateCoefficientOfVariationRules {
    my ($self,%args) = @_;
    my $id_mean        = $args{id_mean},
    my $id_std         = $args{id_std},
    my $extcluster_id  = $args{extcluster_id};
    
    my $combination_params = {
        aggregate_combination_service_provider_id => $extcluster_id,
        aggregate_combination_formula             => 'id'.($id_std).'/ id'.($id_mean),
    };
    
    my $aggregate_combination = AggregateCombination->new(%$combination_params);
    
    my $condition_params = {
        aggregate_condition_service_provider_id => $extcluster_id,
        aggregate_combination_id                => $aggregate_combination->getAttr(name=>'aggregate_combination_id'),
        comparator                              => '>',
        threshold                               => 0.2,
        state                                   => 'enabled',
    };
     
   my $aggregate_condition = AggregateCondition->new(%$condition_params);
    
   my $params_rule = {
        aggregate_rule_service_provider_id  => $extcluster_id,
        aggregate_rule_formula              => 'id'.($aggregate_condition->getAttr(name => 'aggregate_condition_id')),
        aggregate_rule_state                => 'enabled',
#        aggregate_rule_action_id            => $aggregate_condition->getAttr(name => 'aggregate_condition_id'),
        aggregate_rule_label                => 'Heterogeneity detected with '.$aggregate_combination->toString(),
        aggregate_rule_description          => 'All the datas seems homogenous please check the loadbalancer configuration',
    };
    my $aggregate_rule = AggregateRule->new(%$params_rule);
};

# CHECK IF THERE ARE DATA OUT OF MEAN - x SIGMA RANGE
sub generateStandardDevRuleForNormalizedIndicatorsRules {
    my ($self,%args) = @_;
    my $id_std         = $args{id_std},
    my $extcluster_id  = $args{extcluster_id};
    
    my $combination_params = {
        aggregate_combination_service_provider_id => $extcluster_id,
        aggregate_combination_formula             => 'id'.($id_std),
    };
    
    my $aggregate_combination = AggregateCombination->new(%$combination_params);
    
    my $condition_params = {
        aggregate_condition_service_provider_id => $extcluster_id,
        aggregate_combination_id                => $aggregate_combination->getAttr(name=>'aggregate_combination_id'),
        comparator                              => '>',
        threshold                               => 0.15,
        state                                   => 'enabled',
    };
     
   my $aggregate_condition = AggregateCondition->new(%$condition_params);
    
   my $params_rule = {
        aggregate_rule_service_provider_id  => $extcluster_id,
        aggregate_rule_formula              => 'id'.($aggregate_condition->getAttr(name => 'aggregate_condition_id')),
        aggregate_rule_state                => 'enabled',
#        aggregate_rule_action_id            => $aggregate_condition->getAttr(name => 'aggregate_condition_id'),
        aggregate_rule_label                => 'Data homogeneity',
        aggregate_rule_description          => 'All the datas seems homogenous please check the loadbalancer configuration',
    };
    my $aggregate_rule = AggregateRule->new(%$params_rule);
};


sub generateNodeMetricRules{
    my ($self,%args) = @_;
    
    my $indicator_id   = $args{indicator_id};
    my $extcluster_id  = $args{extcluster_id};
    my $indicator_oid  = $args{indicator_oid};
    
    #CREATE A COMBINATION FOR EACH INDICATOR
    my $combination_param = {
        nodemetric_combination_formula => 'id'.$indicator_id,
        nodemetric_combination_service_provider_id => $extcluster_id,
    };
    
    my $comb = NodemetricCombination->new(%$combination_param);

    my $creation_conf = {
        'Memory/PercentMemoryUsed' => {
             comparator      => '>',
             threshold       => 85,
             rule_label      => '%MEM used too high',
             rule_description => 'Percentage memory used is too high, please check this node',
        },
        'Processor/% Processor Time' => {
             comparator      => '>',
             threshold       => 85,
             rule_label      => '%CPU used too high',
             rule_description => 'Percentage processor used is too high, please check this node',
        },
        'LogicalDisk/% Free Space' => {
             comparator      => '<',
             threshold       => 15,
             rule_label      => '%DISK space too low',
             rule_description => 'Percentage disk space is too low, please check this node',
        },
        'Network Adapter/PercentBandwidthUsedTotal' => {
             comparator      => '>',
             threshold       => 85,
             rule_label      => '%Bandwith used too high',
             rule_description => 'Percentage bandwith used is too high, please check this node',
        },
    };
    
    my $condition_param;
    if (defined $creation_conf->{$indicator_oid}){
        my $condition_param = {
            nodemetric_condition_combination_id => $comb->getAttr(name=>'nodemetric_combination_id'),
            nodemetric_condition_comparator     => $creation_conf->{$indicator_oid}->{comparator},
            nodemetric_condition_threshold      => $creation_conf->{$indicator_oid}->{threshold},
            nodemetric_condition_service_provider_id => $extcluster_id,
        };
        my $condition = NodemetricCondition->new(%$condition_param);
        my $conditionid = $condition->getAttr(name => 'nodemetric_condition_id');
        my $prule = {
            nodemetric_rule_formula             => 'id'.$conditionid,
            nodemetric_rule_label               => $creation_conf->{$indicator_oid}->{rule_label},
            nodemetric_rule_description         => $creation_conf->{$indicator_oid}->{rule_description},
            nodemetric_rule_state               => 'enabled',
#            nodemetric_rule_action_id           => undef,
            nodemetric_rule_service_provider_id => $extcluster_id,
        };
        my $rule = NodemetricRule->new(%$prule);
    }
}

1;


#    foreach my $indicator (@indicators) {
#        #For each indicator id get the mean aggregate and the standartdev aggregate to compute mean / standard_dev
#        
#        my @cm_mean = Clustermetric->search(hash => {
#            clustermetric_service_provider_id      => $extcluster_id, 
#            clustermetric_indicator_id             => $indicator,
#            clustermetric_statistics_function_name => 'mean',
#        });
#        
#        my @cm_std = Clustermetric->search(hash => {
#            clustermetric_service_provider_id      => $extcluster_id, 
#            clustermetric_indicator_id             => $indicator,
#            clustermetric_statistics_function_name => 'standard_deviation',
#        });
#        
#        my @cm_ooa = Clustermetric->search(hash => { 
#            clustermetric_service_provider_id      => $extcluster_id, 
#            clustermetric_indicator_id             => $indicator,
#            clustermetric_statistics_function_name => 'numOfDataOutOfRange',
#        });
#        
#        my $id_mean = $cm_mean[0]->getAttr(name=>'clustermetric_id');
#        my $id_std  = $cm_std[0]->getAttr(name=>'clustermetric_id');
#        my $id_ooa  = $cm_ooa[0]->getAttr(name=>'clustermetric_id');
#        
#        $self->generateOutOfRangeRules(
#            id_ooa        => $id_ooa,
#            extcluster_id => $extcluster_id,
#        );
#        $self->generateCoefficientOfVariationRules(
#            id_mean       => $id_mean,
#            id_std        => $id_std,
#            extcluster_id => $extcluster_id,
#        );
#        $self->generateStandardDevRuleForNormalizedIndicatorsRules(
#            id_std        => $id_std,
#            extcluster_id => $extcluster_id,
#        );
#    } #END FOR
