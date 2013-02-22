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

=pod

=begin classdoc

Specific Service Provider representing a cluster not directly managed by Kanopya

=end classdoc

=cut

package Entity::ServiceProvider::Externalcluster;
use base 'Entity::ServiceProvider';

use strict;
use warnings;
use Kanopya::Exceptions;
use General;

use Entity::Combination::NodemetricCombination;
use Entity::NodemetricCondition;
use Entity::Rule::NodemetricRule;
use Entity::Combination::AggregateCombination;
use Entity::AggregateCondition;
use Entity::Rule::AggregateRule;
use Entity::Clustermetric;
use Entity::CollectorIndicator;
use Node;

use Log::Log4perl "get_logger";
use Data::Dumper;

our $VERSION = "1.00";

my $log = get_logger("");
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
        'updateNodes'=> {
            'description'   => 'update nodes',
            'entity'        => 'perm_holder'
        }
    };
}

sub getLabelAttr { return 'externalcluster_name'; }

sub toString() {
    my $self = shift;
    return 'External Cluster ' . $self->getAttr( name => 'externalcluster_name');
}

=head2

    BaseDB label virtual attribute getter

=cut
sub label {
    my $self = shift;
    return $self->externalcluster_name;
}

=head2 addManager

    overload ServiceProvider::addManager to insert initial monitoring configuration when adding a collector manager

    Args: (optionnal) no_default_conf : do not insert default monitoring configuration (link only to indicators. no metrics, no rules)

=cut

sub addManager {
    my $self = shift;
    my %args = @_;

    my $manager = $self->SUPER::addManager( %args );

    if ($args{"manager_type"} eq 'CollectorManager') {
        $self->monitoringDefaultInit( no_default_conf => $args{no_default_conf} );
    }

    return $manager;
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

    $self->{_dbix}->parent->nodes->create({
        node_hostname   => $args{hostname},
        monitoring_state      => 'down',
    });
}

sub getNode {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['node_id']);
    my $repNode;
    my $node = $self->{_dbix}->parent->nodes->find({
        node_id   => $args{node_id},
    });
    $repNode->{hostname} = $node->get_column('node_hostname');
    return $repNode;
}

sub getNodeId {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['hostname']);
    my $node = $self->{_dbix}->parent->nodes->find({
        node_hostname   => $args{hostname},
    });

    return $node->get_column('node_id');
}


=head2 getNodeState


=cut

sub getNodeState {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'hostname' ]);

    return Node->find(hash => { node_hostname => $args{hostname} })->monitoring_state;
}

sub updateNodeState {
    my $self = shift;
    my %args = @_;

    my $hostname = $args{hostname};
    my $state    = $args{state};
    my $host;

    $host = Node->find(hash => {
                node_hostname       => $hostname,
                service_provider_id => $self->id,
            });

    if (defined $host) {
        $host->setAttr(name => 'monitoring_state', value => $state);
        $host->save();
    }
}


sub getDisabledNodes {
    my ($self, %args) = @_;

    my $shortname = defined $args{shortname};

    my $node_rs = $self->{_dbix}->parent->nodes;

    my $domain_name;
    my @nodes;
    while (my $node_row = $node_rs->next) {
        if($node_row->get_column('monitoring_state') eq 'disabled'){
            my $hostname = $node_row->get_column('node_hostname');
            $hostname =~ s/\..*// if ($shortname);
            push @nodes, {
                hostname           => $hostname,
                state              => $node_row->get_column('monitoring_state'),
                id                 => $node_row->get_column('node_id'),
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

=pod

=begin classdoc

Updates nodes list using the linked DirectoryService connector.
If a node is already in cluster then do nothing for it.
Every extra parameter will be transmitted to the DirectoryService connector (e.g password used)

@optional synchro if defined then removes nodes that are no longer present in retrieved nodes list,
                    else keeps all nodes. Default is undef.

@return hashref with 3 keys:
    retrieved_node_count    => total number of nodes retrieved (== total nodes count),
    added_node_count        => number of newly added nodes,
    removed_node_count      => number of removed nodes

=end classdoc

=cut

sub updateNodes {
     my $self = shift;
     my %args = @_;

    General::checkParams(args => \%args, optional => {'synchro' => undef});

     my $ds_manager = $self->getManager( manager_type => 'DirectoryServiceManager' );
     my $mparams    = $self->getManagerParameters( manager_type => 'DirectoryServiceManager' );
     $args{ad_nodes_base_dn}    = $mparams->{ad_nodes_base_dn};

     my $nodes;
     eval {
        $nodes = $ds_manager->getNodes(%args);
     } or do {
        return {error => "$@"};
     };

    # We hashify nodes list for search and delete convenience
    my %nodes_to_add = map { $_->{hostname} => 1 } @$nodes;

    # Differences between current nodes and retrieved nodes
    my @nodes_to_remove;
    for my $node ($self->nodes) {
        if (exists $nodes_to_add{$node->node_hostname}) {
            # node already in cluster, do not add it
            delete $nodes_to_add{$node->node_hostname};
        } else {
            # node not in retrieved list, we delete it (delayed because it's current loop item)
            push @nodes_to_remove, $node;
        }
    }

    # Remove obsolet nodes (mode synchro)
    if (defined $args{synchro}) {
        for my $node (@nodes_to_remove) {
            $node->remove();
        }
    }

    # Add new nodes
    my $added_node_count = 0;
    for my $node_name (keys %nodes_to_add) {
        $self->registerNode(hostname         => $node_name,
                            number           => $added_node_count,
                            state            => 'in',
                            monitoring_state => 'down');
        $added_node_count++;
    }

    return {
        retrieved_node_count    => scalar @$nodes,
        added_node_count        => $added_node_count,
        removed_node_count      => $args{synchro} ? scalar @nodes_to_remove : 0
    };
}

=head2 getNodesMetrics

    Retrieve cluster nodes metrics values using the linked MonitoringService connector

    Params:
        indicators : array ref of indicator name (eg 'ObjectName/CounterName')
        time_span  : number of last seconds to consider when compute average on metric values
        <optional> shortname : bool : node identified by their fqn or hostname in resulting struct
=cut

sub getNodesMetrics {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['indicators', 'time_span']);

    my $shortname = defined $args{shortname};
    my $ms_connector    = $self->getManager(manager_type => 'CollectorManager');
    my $mparams         = $self->getManagerParameters( manager_type => 'CollectorManager' );

    my @hostnames = ();
    my @nodes = $self->nodes;

    for my $node (@nodes) {
        if( ! ($node->monitoring_state eq 'disabled')) {
            push @hostnames, $node->node_hostname
        }
    }

    my $data = $ms_connector->retrieveData(
        nodelist => \@hostnames,
        %args,
        %$mparams
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
    my ($self,%args)  = @_;
    my $extcluster_id = $args{extcluster_id};
    my $indicator_id  = $args{indicator};
    my $func          = $args{func};

    my $cm_params = {
        clustermetric_service_provider_id      => $extcluster_id,
        clustermetric_indicator_id             => $indicator_id,
        clustermetric_statistics_function_name => $func,
        clustermetric_window_time              => '1200',
    };
    my $cm = Entity::Clustermetric->new(%$cm_params);

    my $acf_params = {
        service_provider_id             => $extcluster_id,
        aggregate_combination_formula   => 'id'.($cm->getAttr(name => 'clustermetric_id'))
    };
    my $aggregate_combination = Entity::Combination::AggregateCombination->new(%$acf_params);
    my $rep = {
        cm_id => $cm->getAttr(name => 'clustermetric_id'),
        comb_id => $aggregate_combination->id,
    };
    return $rep;
}

=head2 monitoringDefaultInit

    Insert some basic clustermetrics, combinations and rules for this cluster

    Use SCOM indicators by default
    TODO : more generic (unhardcode SCOM, metrics depend on monitoring service)
    TODO : default init must be done when instanciating data collector.

    Args: (optionnal) no_default_conf : do not insert default monitoring configuration (link only to indicators. no metrics, no rules)

=cut

sub monitoringDefaultInit {
    my ($self, %args) = @_;

    return if ($args{no_default_conf});

    my $service_provider_id = $self->id;
    my @collector_indicators = $self->getManager(manager_type => "CollectorManager")->collector_indicators;

    my $active_session_indicator_id;
    my ($low_mean_cond_mem_id, $low_mean_cond_cpu_id, $low_mean_cond_net_id);
    my @funcs = qw(mean max min std dataOut);

    foreach my $collector_indicator (@collector_indicators) {
        my $indicator_id  = $collector_indicator->id;
        my $indicator_oid = $collector_indicator->indicator->indicator_oid;

        if ($indicator_oid eq 'Terminal Services/Active Sessions') {
            $active_session_indicator_id = $indicator_id;
        }

        $self->generateNodeMetricRules(
            indicator_id  => $indicator_id,
            indicator_oid => $indicator_oid,
            extcluster_id => $service_provider_id,
        );

     if (
        0 == grep {$indicator_oid eq $_} ('Memory/PercentMemoryUsed','Processor/% Processor Time','Network Adapter/PercentBandwidthUsedTotal','LogicalDisk/% Free Space')
        ){
            foreach my $func (@funcs) {
                $self->generateClustermetricAndCombination(
                    extcluster_id => $service_provider_id,
                    indicator     => $indicator_id,
                    func          => $func,
                );
            }
        }
        elsif($indicator_oid eq 'Memory/PercentMemoryUsed'){
            $low_mean_cond_mem_id = $self->ruleGeneration(indicator_id => $indicator_id, extcluster_id => $service_provider_id, label => 'Memory');
        }
        elsif($indicator_oid eq 'Processor/% Processor Time'){
            $low_mean_cond_cpu_id = $self->ruleGeneration(indicator_id => $indicator_id, extcluster_id => $service_provider_id, label => 'Processor');
        }
        elsif($indicator_oid eq 'Network Adapter/PercentBandwidthUsedTotal'){
            $low_mean_cond_net_id = $self->ruleGeneration(indicator_id => $indicator_id, extcluster_id => $service_provider_id, label => 'Network');
        }
    }

    if(defined $low_mean_cond_mem_id && $low_mean_cond_cpu_id && $low_mean_cond_net_id) {
        my $params_rule = {
            service_provider_id  => $service_provider_id,
            aggregate_rule_formula              => 'id'.$low_mean_cond_mem_id.'&&'.'id'.$low_mean_cond_cpu_id.'&&'.'id'.$low_mean_cond_net_id,
            aggregate_rule_state                => 'enabled',
            aggregate_rule_label                => 'Cluster load',
            aggregate_rule_description          => 'Mem, cpu and network usages are low, your cluster may be oversized',
        };
        Entity::Rule::AggregateRule->new(%$params_rule);
    }

    if(defined $active_session_indicator_id) {
        #SPECIAL TAKE SUM OF SESSION ID
        my $cm_params = {
            clustermetric_service_provider_id      => $service_provider_id,
            clustermetric_indicator_id             => $active_session_indicator_id,
            clustermetric_statistics_function_name => 'sum',
            clustermetric_window_time              => '1200',
        };
        my $cm = Entity::Clustermetric->new(%$cm_params);

        my $acf_params = {
            service_provider_id             => $service_provider_id,
            aggregate_combination_formula   => 'id'.($cm->getAttr(name => 'clustermetric_id'))
        };
        Entity::Combination::AggregateCombination->new(%$acf_params);
    }
}

sub ruleGeneration{
    my ($self,%args) = @_;
    my $indicator_id     = $args{indicator_id};
    my $extcluster_id = $args{extcluster_id};
    my $label         = $args{label};

    my @funcs = qw(max min);
    foreach my $func (@funcs) {
        $self->generateClustermetricAndCombination(
                extcluster_id => $extcluster_id,
                indicator     => $indicator_id,
                func          => $func,
            );
    }

    my $mean_ids = $self->generateClustermetricAndCombination(
        extcluster_id => $extcluster_id,
        indicator     => $indicator_id,
        func          => 'mean',
    );
    my $std_ids = $self->generateClustermetricAndCombination(
        extcluster_id => $extcluster_id,
        indicator     => $indicator_id,
        func          => 'std',
    );

    my $out_ids = $self->generateClustermetricAndCombination(
        extcluster_id => $extcluster_id,
        indicator     => $indicator_id,
        func          => 'dataOut',
    );

    my $combination_params = {
        service_provider_id             => $extcluster_id,
        aggregate_combination_formula   => 'id'.($std_ids->{cm_id}).'/ id'.($mean_ids->{cm_id}),
    };

    my $coef_comb = Entity::Combination::AggregateCombination->new(%$combination_params);

   my $condition_params = {
        aggregate_condition_service_provider_id => $extcluster_id,
        left_combination_id                => $coef_comb->id,
        comparator                              => '>',
        threshold                               => 0.2,
    };

   my $coef_cond = Entity::AggregateCondition->new(%$condition_params);
   my $coef_cond_id = $coef_cond->getAttr(name => 'aggregate_condition_id');

   $condition_params = {
        aggregate_condition_service_provider_id => $extcluster_id,
        left_combination_id                => $std_ids->{comb_id},
        comparator                              => '>',
        threshold                               => 10,
    };

   my $std_cond = Entity::AggregateCondition->new(%$condition_params);
   my $std_cond_id = $std_cond->getAttr(name => 'aggregate_condition_id');

   $condition_params = {
        aggregate_condition_service_provider_id => $extcluster_id,
        left_combination_id                     => $out_ids->{comb_id},
        comparator                              => '>',
        threshold                               => 0,
    };

   my $out_cond = Entity::AggregateCondition->new(%$condition_params);
   my $out_cond_id = $out_cond->getAttr(name => 'aggregate_condition_id');

   my $params_rule = {
        service_provider_id  => $extcluster_id,
        aggregate_rule_formula              => 'id'.$coef_cond_id.' && '.'id'.$std_cond_id,
        aggregate_rule_state                => 'enabled',
        aggregate_rule_label                => 'Cluster '.$label.' homogeneity',
        aggregate_rule_description          => $label.' is not well balanced across the cluster',
    };
    Entity::Rule::AggregateRule->new(%$params_rule);

   $params_rule = {
        service_provider_id  => $extcluster_id,
        aggregate_rule_formula              => 'id'.$out_cond_id,
        aggregate_rule_state                => 'enabled',
        aggregate_rule_label                => 'Cluster '.$label.' consistency',
        aggregate_rule_description          => 'The '.$label.' usage of some nodes of the cluster is far from the average behavior',
    };
    Entity::Rule::AggregateRule->new(%$params_rule);

   $condition_params = {
        aggregate_condition_service_provider_id => $extcluster_id,
        left_combination_id                     => $mean_ids->{comb_id},
        comparator                              => '>',
        threshold                               => 80,
    };

   my $mean_cond = Entity::AggregateCondition->new(%$condition_params);
   my $mean_cond_id = $mean_cond->getAttr(name => 'aggregate_condition_id');
   $params_rule = {
        service_provider_id  => $extcluster_id,
        aggregate_rule_formula              => 'id'.$mean_cond_id,
        aggregate_rule_state                => 'enabled',
        aggregate_rule_label                => 'Cluster '.$label.' overload',
        aggregate_rule_description          => 'Average '.$label.' is too high, your cluster may be undersized',
    };
    Entity::Rule::AggregateRule->new(%$params_rule);

   $condition_params = {
        aggregate_condition_service_provider_id => $extcluster_id,
        left_combination_id                     => $mean_ids->{comb_id},
        comparator                              => '<',
        threshold                               => 10,
    };

   my $low_mean_cond = Entity::AggregateCondition->new(%$condition_params);

   return $low_mean_cond->getAttr(name => 'aggregate_condition_id');
}

# CHECK IF THERE ARE DATA OUT OF MEAN - x SIGMA RANGE
sub generateAOutOfRangeRule {
    my ($self,%args) = @_;
    my $ndoor_comb_id            = $args{ndoor_comb_id};
    my $extcluster_id            = $args{extcluster_id};

    my $condition_params = {
        aggregate_condition_service_provider_id => $extcluster_id,
        left_combination_id                     => $ndoor_comb_id,
        comparator                              => '>',
        threshold                               => 0,
    };

    my $aggregate_condition = Entity::AggregateCondition->new(%$condition_params);
    my $label = 'Isolated data - '.$aggregate_condition->left_combination->toString();

    my $params_rule = {
        service_provider_id  => $extcluster_id,
        aggregate_rule_formula              => 'id'.($aggregate_condition->getAttr(name => 'aggregate_condition_id')),
        aggregate_rule_state                => 'enabled',
        aggregate_rule_label                => $label,
        aggregate_rule_description          => 'Check the indicators of the nodes generating isolated datas',
    };
    Entity::Rule::AggregateRule->new(%$params_rule);
};

sub generateOverRules {
    my ($self,%args) = @_;
    my $mean_percent_comb_id     = $args{mean_percent_comb_id};
    my $extcluster_id            = $args{extcluster_id};

    my $condition_params = {
        aggregate_condition_service_provider_id => $extcluster_id,
        left_combination_id                     => $mean_percent_comb_id,
    };

   $condition_params->{comparator} = '>';
   $condition_params->{threshold}  = 70;

   my $aggregate_condition = Entity::AggregateCondition->new(%$condition_params);

   my $params_rule = {
        service_provider_id  => $extcluster_id,
        aggregate_rule_formula              => 'id'.($aggregate_condition->getAttr(name => 'aggregate_condition_id')),
        aggregate_rule_state                => 'enabled',
    };

    $params_rule->{aggregate_rule_label}       = 'Cluster '.$aggregate_condition->left_combination->toString().' overloaded';
    $params_rule->{aggregate_rule_description} = 'You may add a node';

    Entity::Rule::AggregateRule->new(%$params_rule);
};


sub generateUnderRules {
    my ($self,%args) = @_;
    my $mean_percent_comb_id     = $args{mean_percent_comb_id};
    my $extcluster_id            = $args{extcluster_id};

    my $condition_params = {
        aggregate_condition_service_provider_id => $extcluster_id,
        left_combination_id                     => $mean_percent_comb_id,
    };

   $condition_params->{comparator} = '<';
   $condition_params->{threshold}  = 10;

   my $aggregate_condition = Enity::AggregateCondition->new(%$condition_params);

   my $params_rule = {
        service_provider_id  => $extcluster_id,
        aggregate_rule_formula              => 'id'.($aggregate_condition->getAttr(name => 'aggregate_condition_id')),
        aggregate_rule_state                => 'enabled',
    };

    $params_rule->{aggregate_rule_label}       = 'Cluster '.$aggregate_condition->left_combination->toString().' underloaded';
    $params_rule->{aggregate_rule_description} = 'You may add a node';

    Entity::Rule::AggregateRule->new(%$params_rule);
};

# CHECK IF THERE ARE DATA OUT OF MEAN - x SIGMA RANGE
sub generateCoefficientOfVariationRules {
    my ($self,%args) = @_;
    my $id_mean        = $args{id_mean},
    my $id_std         = $args{id_std},
    my $extcluster_id  = $args{extcluster_id};

    my $combination_params = {
        service_provider_id             => $extcluster_id,
        aggregate_combination_formula   => 'id'.($id_std).'/ id'.($id_mean),
    };

    my $aggregate_combination = Entity::Combination::AggregateCombination->new(%$combination_params);

    my $condition_params = {
        aggregate_condition_service_provider_id => $extcluster_id,
        left_combination_id                     => $aggregate_combination->id,
        comparator                              => '>',
        threshold                               => 0.2,
    };

   my $aggregate_condition = Entity::AggregateCondition->new(%$condition_params);

   my $params_rule = {
        service_provider_id  => $extcluster_id,
        aggregate_rule_formula              => 'id'.($aggregate_condition->getAttr(name => 'aggregate_condition_id')),
        aggregate_rule_state                => 'enabled',
        aggregate_rule_label                => 'Heterogeneity detected with '.$aggregate_combination->toString(),
        aggregate_rule_description          => 'All the datas seems homogenous please check the loadbalancer configuration',
    };
    Entity::Rule::AggregateRule->new(%$params_rule);
};

# CHECK IF THERE ARE DATA OUT OF MEAN - x SIGMA RANGE
sub generateStandardDevRuleForNormalizedIndicatorsRules {
    my ($self,%args) = @_;
    my $id_std         = $args{id_std},
    my $extcluster_id  = $args{extcluster_id};

    my $combination_params = {
        service_provider_id             => $extcluster_id,
        aggregate_combination_formula   => 'id'.($id_std),
    };

    my $aggregate_combination = Entity::Combination::AggregateCombination->new(%$combination_params);

    my $condition_params = {
        aggregate_condition_service_provider_id => $extcluster_id,
        left_combination_id                => $aggregate_combination->id,
        comparator                              => '>',
        threshold                               => 0.15,
    };

   my $aggregate_condition = Entity::AggregateCondition->new(%$condition_params);

   my $params_rule = {
        service_provider_id  => $extcluster_id,
        aggregate_rule_formula              => 'id'.($aggregate_condition->getAttr(name => 'aggregate_condition_id')),
        aggregate_rule_state                => 'enabled',
        aggregate_rule_label                => 'Data homogeneity',
        aggregate_rule_description          => 'All the datas seems homogenous please check the loadbalancer configuration',
    };
    Entity::Rule::AggregateRule->new(%$params_rule);
};


sub generateNodeMetricRules{
    my ($self,%args) = @_;

    my $indicator_id   = $args{indicator_id};
    my $extcluster_id  = $args{extcluster_id};
    my $indicator_oid  = $args{indicator_oid};

    #CREATE A COMBINATION FOR EACH INDICATOR
    my $combination_param = {
        nodemetric_combination_formula  => 'id'.$indicator_id,
        service_provider_id             => $extcluster_id,
    };

    my $comb = Entity::Combination::NodemetricCombination->new(%$combination_param);

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

    if (defined $creation_conf->{$indicator_oid}){
        my $condition_param = {
            left_combination_id => $comb->getAttr(name=>'nodemetric_combination_id'),
            nodemetric_condition_comparator     => $creation_conf->{$indicator_oid}->{comparator},
            nodemetric_condition_threshold      => $creation_conf->{$indicator_oid}->{threshold},
            nodemetric_condition_service_provider_id => $extcluster_id,
        };
        my $condition = Entity::NodemetricCondition->new(%$condition_param);
        my $conditionid = $condition->getAttr(name => 'nodemetric_condition_id');
        my $prule = {
            nodemetric_rule_formula             => 'id'.$conditionid,
            nodemetric_rule_label               => $creation_conf->{$indicator_oid}->{rule_label},
            nodemetric_rule_description         => $creation_conf->{$indicator_oid}->{rule_description},
            nodemetric_rule_state               => 'enabled',
            service_provider_id => $extcluster_id,
        };
        Entity::Rule::NodemetricRule->new(%$prule);
    }
}


=head2 remove

    Desc: manually remove associated connectors (don't use cascade delete)
          so each one can manually remove associated service_provider_manager
          Managers can't be cascade deleted because they are linked either to a a connector or a component.

    TODO : merge connector and component or make them inerit from a parent class

=cut

sub remove {
    my $self = shift;

    my @components = $self->components;
    for my $component (@components) {
        $component->remove();
    }

    $self->delete();
}

1;
