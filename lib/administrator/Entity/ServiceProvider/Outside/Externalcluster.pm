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

use Clustermetric;
use AggregateCombination;
use AggregateCondition;
use AggregateRule;

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
    externalcluster_state   => {pattern         => '^up:\d*|down:\d*|starting:\d*|stopping:\d*$',
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
        externalnode_state      => 'up',
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
sub getNodes {
    my $self = shift;
    my %args = @_;

    my $shortname = defined $args{shortname};

    my $node_rs = $self->{_dbix}->parent->externalnodes;

    my $domain_name;
    my @nodes;
    while (my $node_row = $node_rs->next) {
        my $hostname = $node_row->get_column('externalnode_hostname');
        $hostname =~ s/\..*// if ($shortname);
        push @nodes, {
            hostname           => $hostname,
            state              => $node_row->get_column('externalnode_state'),
            id                 => $node_row->get_column('externalnode_id'),
            num_verified_rules => $node_row->verified_noderules->count(),
        };
    }

    return \@nodes;
}

=head2 updateNodes

    Update external nodes list using the linked DirectoryService connector

=cut

sub updateNodes {
     my $self = shift;
     
     my $ds_connector = $self->getConnector( category => 'DirectoryService' );
     my $nodes = $ds_connector->getNodes();
     
     for my $node (@$nodes) {
         if (defined $node->{hostname}) {
            $self->{_dbix}->parent->externalnodes->update_or_create({
                externalnode_hostname   => $node->{hostname},
                externalnode_state      => 'up',
            });
         }
     }
     # TODO remove dead nodes from db
}

=head2 getNodesMetrics

    Retrieve cluster nodes metrics values using the linked MonitoringService connector
    
    Params:
        indicators : array ref of indicator name (eg 'ObjectName/CounterName')
        time_span  : number of last seconds to consider when compute average on metric values
=cut

sub getNodesMetrics {
     my $self = shift;
     my %args = @_;

     General::checkParams(args => \%args, required => ['indicators', 'time_span']);
     
     my $ms_connector = $self->getConnector( category => 'MonitoringService' );
     my $nodes = $self->getNodes();
     
     my @hostnames = map { $_->{hostname} } @$nodes;
     
     my $data = $ms_connector->retrieveData(
        nodes => \@hostnames,
        %args,
     );

    my %data_shortnodename;
    while (my ($nodename, $metrics) = each %$data) {
         $nodename =~ s/\..*//;
         $data_shortnodename{$nodename} = $metrics;
    }

    return \%data_shortnodename;
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
    my @indicators;
    my @funcs = qw(mean max min standard_deviation numOfDataOutOfRange);
    foreach my $indicator (@{$scom_indicatorset->{ds}}){
        push @indicators, $indicator->{id};
    }

    my $extcluster_id = $self->getAttr( name => 'outside_id' );

   # Create one clustermetric for each indicator scom
    # Create 4 aggregates for each cluster metric
    # Create the corresponding combination 'identity function' for each aggregate 
    foreach my $indicator (@{$scom_indicatorset->{ds}}) {
        
        $self->generateNodeMetricRules(
            indicator_id  => $indicator->{id},
            extcluster_id => $extcluster_id,
            );
        
        # GENERATE CLUSTER METRICS
        # TODO : specific method
        
        foreach my $func (@funcs) {
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
        }
    }
    
    
    
    #Create conditions
    
    foreach my $indicator (@indicators) {
        
        #For each indicator id get the max aggregate and the min aggregate to compute max - min
#
#        my @cm_max = Clustermetric->search(hash => { 
#            clustermetric_indicator_id => $indicator,
#            clustermetric_statistics_function_name => 'max',
#        });
#        
#        my @cm_min = Clustermetric->search(hash => { 
#            clustermetric_indicator_id => $indicator,
#            clustermetric_statistics_function_name => 'min',
#        });
#        
#        my $id_min = $cm_min[0]->getAttr(name=>'clustermetric_id');
#        my $id_max = $cm_max[0]->getAttr(name=>'clustermetric_id'); 
        
        #For each indicator id get the mean aggregate and the standartdev aggregate to compute mean / standard_dev
        
        my @cm_mean = Clustermetric->search(hash => { 
            clustermetric_indicator_id => $indicator,
            clustermetric_statistics_function_name => 'mean',
        });
        
        my @cm_std = Clustermetric->search(hash => { 
            clustermetric_indicator_id => $indicator,
            clustermetric_statistics_function_name => 'standard_deviation',
        });
        
        my @cm_ooa = Clustermetric->search(hash => { 
            clustermetric_indicator_id => $indicator,
            clustermetric_statistics_function_name => 'numOfDataOutOfRange',
        });
        
        my $id_mean = $cm_mean[0]->getAttr(name=>'clustermetric_id');
        my $id_std  = $cm_std[0]->getAttr(name=>'clustermetric_id');
        my $id_ooa  = $cm_ooa[0]->getAttr(name=>'clustermetric_id'); 
        

#        $acf_params->{aggregate_combination_formula} = '(id'.($id_max).'- id'.($id_min).') / id'.($id_mean);
#        my $aggregate_combination_range_over_mean = AggregateCombination->new(%$acf_params);
#
#        $acf_params->{aggregate_combination_formula} = '(id'.($id_max).'- id'.($id_min).') / id'.($id_std);
#        my $aggregate_combination_range_over_std = AggregateCombination->new(%$acf_params);


        $self->generateOutOfRangeRules(
            clustermetric_id => $id_ooa,
            extcluster_id    => $extcluster_id,
        );
        $self->generateCoefficientOfVariationRules(
            id_mean       => $id_mean,
            id_std        => $id_std,
            extcluster_id => $extcluster_id,
        );
        $self->generateStandardDevRuleForNormalizedIndicatorsRules(
            id_std        => $id_std,
            extcluster_id => $extcluster_id,
        );

    };

#            aggregate_combination_formula             => 'id'.($id_std).'/ id'.($id_mean),

    # CHECK IF THERE ARE DATA OUT OF MEAN - x SIGMA RANGE
    sub generateOutOfRangeRules {
        my ($self,%args) = @_;
        my $clustermetric_id = $args{clustermetric_id};
        my $extcluster_id    = $args{extcluster_id};
        
        my $combination_params = {
            aggregate_combination_service_provider_id => $extcluster_id,
            aggregate_combination_formula             => 'id'.($clustermetric_id),
        };
        
        my $aggregate_combination = AggregateCombination->new(%$combination_params);
        
        my $condition_params = {
            aggregate_condition_service_provider_id => $extcluster_id,
            aggregate_combination_id                => $aggregate_combination->getAttr(name=>'aggregate_combination_id'),
            comparator                              => '>',
            threshold                               => 0,
            state                                   => 'enabled',
        };
         
       my $aggregate_condition = AggregateCondition->new(%$condition_params);

       my $params_rule = {
            aggregate_rule_service_provider_id  => $extcluster_id,
            aggregate_rule_formula              => 'id'.($aggregate_condition->getAttr(name => 'aggregate_condition_id')),
            aggregate_rule_state                => 'enabled',
            aggregate_rule_action_id            => $aggregate_condition->getAttr(name => 'aggregate_condition_id'),
            aggregate_rule_label                => 'Mainly homogenous datas with isolated values',
            aggregate_rule_description          => 'Check the indicators of the nodes generating isolated datas',
        };
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
            aggregate_rule_action_id            => $aggregate_condition->getAttr(name => 'aggregate_condition_id'),
            aggregate_rule_label                => 'Data homogeneity',
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
            aggregate_rule_action_id            => $aggregate_condition->getAttr(name => 'aggregate_condition_id'),
            aggregate_rule_label                => 'Data homogeneity',
            aggregate_rule_description          => 'All the datas seems homogenous please check the loadbalancer configuration',
        };
        my $aggregate_rule = AggregateRule->new(%$params_rule);
    };
    
    sub generateNodeMetricRules{
        my ($self,%args) = @_;

        my $indicator_id   = $args{indicator_id};
        my $extcluster_id  = $args{extcluster_id};

        my $combination_param = {
            nodemetric_combination_formula => 'id'.$indicator_id,
        };
        
        my $comb = NodemetricCombination->new(%$combination_param);
        
        my $condition_param = {
            nodemetric_condition_combination_id => $comb->getAttr(name=>'nodemetric_combination_id'),
            nodemetric_condition_comparator     => ">",
            nodemetric_condition_threshold      => 85,
        };
        
        my $condition = NodemetricCondition->new(%$condition_param);
        
        
        my $conditionid = $condition->getAttr(name => 'nodemetric_condition_id');
        my $prule = {
            nodemetric_rule_formula             => 'id'.$conditionid,
            nodemetric_rule_label               => 'id'.$conditionid,
            nodemetric_rule_label               => 'Metric over loaded',
            nodemetric_rule_description         => 'This node is overloaded, check its configuration',
            nodemetric_rule_state               => 'enabled',
            nodemetric_rule_action_id           => '1',
            nodemetric_rule_service_provider_id => $extcluster_id,
        };
        my $rule = NodemetricRule->new(%$prule);

        $condition_param = {
            nodemetric_condition_combination_id => $comb->getAttr(name=>'nodemetric_combination_id'),
            nodemetric_condition_comparator     => "<",
            nodemetric_condition_threshold      => 10,
        };
        
        $condition = NodemetricCondition->new(%$condition_param);
        
        
        $conditionid = $condition->getAttr(name => 'nodemetric_condition_id');
        $prule = {
            nodemetric_rule_formula             => 'id'.$conditionid,
            nodemetric_rule_label               => 'id'.$conditionid,
            nodemetric_rule_label               => 'Metric over loaded',
            nodemetric_rule_description         => 'This node is overloaded, check its configuration',
            nodemetric_rule_state               => 'enabled',
            nodemetric_rule_action_id           => '1',
            nodemetric_rule_service_provider_id => $extcluster_id,
        };
        $rule = NodemetricRule->new(%$prule);
      }
}


1;
