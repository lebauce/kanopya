=pod

=begin classdoc

Subroutines to upgrade KIO

@since 2013-March-26

=end classdoc

=cut


package Kanopya::Tools::KioImport;

use strict;
use warnings;

use Data::Dumper;
use General;
use JSON;
use Kanopya::Exceptions;
use BaseDB;
use Entity::Component;
use Entity::Component::ActiveDirectory;
use Entity::Component::Scom;
use Entity::Component::Sco;
use Node;
use Entity::Rule::AggregateRule;
use ServiceProviderManager;
use Entity::Combination::AggregateCombination;
use Entity::AggregateCondition;
use Entity::ServiceProvider::Cluster;
use Entity::Clustermetric;
use Entity::CollectorIndicator;
use Entity::Indicator;
use Entity::Combination::ConstantCombination;
use Dashboard;
use Entity::Host;
use Entity::Indicator;
use Entity::Combination::NodemetricCombination;
use Entity::NodemetricCondition;
use Entity::Rule::NodemetricRule;
use ParamPreset;
use Entity::User;
use UserProfile;
use VerifiedNoderule;
use Entity::WorkflowDef;
use Entity::ServiceProvider::Externalcluster;
use ClassType::ComponentType;
use Kanopya::Config;
use Indicatorset;

BaseDB->authenticate( login =>'admin', password => 'K4n0pY4' );
BaseDB->beginTransaction;

eval {
    importKanopyaData();
};
if ($@) {
    my $error = $@;
    print 'Error in data import : ' . $error . "\n";
    BaseDB->rollbackTransaction;
}
else {
    BaseDB->commitTransaction;
    print "Data imported successfully\n";
}

sub importKanopyaData {
    my ($export_dir, $rrd_backup_dir, $rrd_dir);
    my ($cp_file, $del_file);

    # rrd backup parameters
    if ($^O eq 'MSWin32') {
        $export_dir     = 'C:\\tmp\\';
        $rrd_backup_dir = 'C:\\tmp\\monitor\\TimeData_backup\\';
        $rrd_dir        = 'C:\\tmp\\monitor\\TimeData\\';
        $cp_file        = 'cp';
        $del_file       = 'del';
    }
    elsif ($^O eq 'linux') {
        $export_dir     = '/vagrant/';
        $rrd_backup_dir = '/var/cache/kanopya/monitor_backup/';
        $rrd_dir        = '/var/cache/kanopya/monitor/';
        $cp_file        = 'cp';
        $del_file       = 'rm';
    }

    my $export_bdd_file = $export_dir . 'bdd.json';

    open (my $FILE, '<', $export_bdd_file) or die 'could not open \'$export_bdd_file\' : $!\n';
    my $import;
    while (my $line  = <$FILE>) {
        $import .= $line;
    }
    close($FILE);

    my $json_imported_items = JSON->new->utf8->decode($import);

    my $services = $json_imported_items->{services};
    my $user_indicators = $json_imported_items->{user_indicators};

    # We need to map old ids to new ones for data updates
    # reminder:
    # AggregateCombination formula  => clustermetric ids
    # NodemetricCombination formula => collector indicator ids
    # AggregateRule                 => AggregateCondition ids
    # NodemetricRule                => NodemetricCondition ids
    # ids in RRD filenames          => clustermetric ids

    my $collector_indicator_map;
    my $clustermetric_map;
    my $service_provider_map;
    my $combination_map;
    my $aggregate_condition_map;
    my $nodemetric_condition_map;
    my $formula_map;
    my @service_providers = grep {not defined $_->{connectors} } @$services;
    my @technical_services = grep {defined $_->{connectors} } @$services;

    # register service providers with component(s) (technical services)
    for my $technical_service (@technical_services) {

        my $new_externalcluster = Entity::ServiceProvider::Externalcluster->new(
            externalcluster_name       => $technical_service->{externalcluster_name},
            externalcluster_desc       => $technical_service->{externalcluster_desc},
            externalcluster_state      => $technical_service->{externalcluster_state},
            externalcluster_prev_state => $technical_service->{externalcluster_prev_state},
        );

        $service_provider_map->{$technical_service->{service_provider_id}} =
            $new_externalcluster;

        # register component(s)
        for my $connector (@{ $technical_service->{connectors} }) {
            my $component_type_id = ClassType::ComponentType->find(hash => {
                                        component_name => $connector->{connector_type}
                                    })->id;

            my $component_class_type = 'Entity::Component::' . $connector->{connector_type};
            my $component = $component_class_type->new(
                component_type_id     => $component_type_id,
                service_provider_id   => $new_externalcluster->id,
            );

            if (defined $connector->{collector_indicators}) {

                foreach my $old_collector_indicator (@{ $connector->{collector_indicators} }) {
                    my $old_indicator_name = $old_collector_indicator->{indicator_name};
                    my $indicator_id;
                    eval{
                        $indicator_id = Entity::Indicator->find( hash => {
                                             indicator_name => $old_indicator_name,
                                           })->id;
                    };
                    if ($@) {
                        my $old_indicator_id = $old_collector_indicator->{indicator_id};
                        $indicator_id = Entity::Indicator->new(
                            indicator_name => $user_indicators->{$old_indicator_id}->{indicator_name},
                            indicator_label => $user_indicators->{$old_indicator_id}->{indicator_label},
                            indicator_oid => $user_indicators->{$old_indicator_id}->{indicator_oid},
                            indicator_min => $user_indicators->{$old_indicator_id}->{indicator_min},
                            indicator_max => $user_indicators->{$old_indicator_id}->{indicator_max},
                            indicator_unit => $user_indicators->{$old_indicator_id}->{indicator_unit},
                            indicatorset_id => Indicatorset->find(
                                hash => {
                                    indicatorset_name =>
                                        $user_indicators->{$old_indicator_id}->{indicatorset_name}
                                }
                            )->indicatorset_id,
                        )->id;
                    }

                    $collector_indicator_map->{$old_collector_indicator->{collector_indicator_id}} =
                        Entity::CollectorIndicator->new(
                            collector_manager_id => $component->id,
                            indicator_id         => $indicator_id,
                        )->id;
                }

                $formula_map->{collector_indicators} = $collector_indicator_map;
            }
        }
    }

    # register service providers with managers
    for my $service_provider (@service_providers) {
        my $new_externalcluster = Entity::ServiceProvider::Externalcluster->new(
            externalcluster_name       => $service_provider->{externalcluster_name},
            externalcluster_desc       => $service_provider->{externalcluster_desc},
            externalcluster_state      => $service_provider->{externalcluster_state},
            externalcluster_prev_state => $service_provider->{externalcluster_prev_state}
        );

        # register node(s)
        if (defined @{ $service_provider->{externalnodes} }) {
            for my $old_externalnode (@{ $service_provider->{externalnodes} }) {
                my $new_node = Node->new(
                    node_hostname       => $old_externalnode->{externalnode_hostname},
                    node_number         => 0,
                    monitoring_state    => $old_externalnode->{externalnode_state},
                    service_provider_id => $new_externalcluster->id
                );
            }
        }

        $service_provider_map->{$service_provider->{service_provider_id}} =
            $new_externalcluster;

        my $manager_categories = {
            directory_service_manager => 'DirectoryServiceManager',
            collector_manager         => 'CollectorManager',
            workflow_manager          => 'WorkflowManager',
        };

        foreach my $old_manager (@{ $service_provider->{service_provider_managers} }) {
            my $manager_service_provider =
                $service_provider_map->{$old_manager->{origin_service_id}};

            my $manager_id = $manager_service_provider->getComponent(
                                 category => $manager_categories->{$old_manager->{manager_type}}
                             )->id;

            $new_externalcluster->addManager(
                manager_id      => $manager_id,
                manager_type    => $manager_categories->{$old_manager->{manager_type}},
                no_default_conf => 1,
            );
        }

        for my $old_clustermetric (@{ $service_provider->{clustermetrics} }) {
            my $clustermetric_indicator_id =
                $collector_indicator_map->{ $old_clustermetric->{clustermetric_indicator_id} };

            $clustermetric_map->{$old_clustermetric->{clustermetric_id}} =
                Entity::Clustermetric->new(
                    clustermetric_label                    => $old_clustermetric->{clustermetric_label},
                    clustermetric_indicator_id             => $clustermetric_indicator_id,
                    clustermetric_statistics_function_name => $old_clustermetric->{clustermetric_statistics_function_name},
                    clustermetric_formula_string           => $old_clustermetric->{clustermetric_formula_string},
                    clustermetric_unit                     => $old_clustermetric->{clustermetric_unit},
                    clustermetric_window_time              => $old_clustermetric->{clustermetric_window_time},
                    clustermetric_service_provider_id      => $new_externalcluster->id
                )->id;
        }
        $formula_map->{clustermetrics} = $clustermetric_map;

        #register combinations
        foreach my $old_combination (@{ $service_provider->{combinations} }) {
            my $combination_id;
            if (defined $old_combination->{aggregate_combination_id}) {
                #we update the old formula with the new ids
                my $ac_formula = $old_combination->{aggregate_combination_formula};
                $ac_formula =~ s/id(\d+)/id$formula_map->{clustermetrics}->{$1}/g;

                $combination_id = Entity::Combination::AggregateCombination->new(
                    aggregate_combination_label           => $old_combination->{aggregate_combination_label},
                    aggregate_combination_formula         => $ac_formula,
                    aggregate_combination_formula_string  => $old_combination->{aggregate_combination_formula_string},
                    combination_unit                      => $old_combination->{combination_unit},
                    service_provider_id                   => $new_externalcluster->id,
                )->id;
                $combination_map->{ $old_combination->{aggregate_combination_id} } = $combination_id;
            }
            elsif (defined $old_combination->{nodemetric_combination_id}) {
                #we update the old formula with the new ids
                my $nc_formula =  $old_combination->{nodemetric_combination_formula};
                $nc_formula =~ s/id(\d+)/id$formula_map->{collector_indicators}->{$1}/g;

                $combination_id = Entity::Combination::NodemetricCombination->new(
                    nodemetric_combination_label          => $old_combination->{nodemetric_combination_label},
                    nodemetric_combination_formula        => $nc_formula,
                    nodemetric_combination_formula_string => $old_combination->{nodemetric_combination_formula_string},
                    combination_unit                      => $old_combination->{combination_unit},
                    service_provider_id                   => $new_externalcluster->id,
                )->id;
                $combination_map->{ $old_combination->{nodemetric_combination_id} } = $combination_id;
            }
            elsif (defined $old_combination->{constant_combination_id}) { # constant combination
                $combination_id = Entity::Combination::ConstantCombination->new(
                    value               => $old_combination->{value},
                    combination_unit    => $old_combination->{combination_unit},
                    service_provider_id => $new_externalcluster->id,
                )->id;
                $combination_map->{ $old_combination->{constant_combination_id} } = $combination_id
            }
        }

        # register aggregate conditions
        foreach my $old_agg_condition (@{ $service_provider->{aggregate_conditions} }) {
            my $left_combination_id = $combination_map->{ $old_agg_condition->{left_combination_id} };
            my $right_combination_id = $combination_map->{ $old_agg_condition->{right_combination_id} };
            my $aggregate_condition_id = Entity::AggregateCondition->new(
                aggregate_condition_label               => $old_agg_condition->{aggregate_condition_label},
                aggregate_condition_formula_string      => $old_agg_condition->{aggregate_condition_formula_string},
                comparator                              => $old_agg_condition->{comparator},
                left_combination_id                     => $left_combination_id,
                right_combination_id                    => $right_combination_id,
                aggregate_condition_service_provider_id => $new_externalcluster->id,
            )->id;
            $aggregate_condition_map->{ $old_agg_condition->{aggregate_condition_id} } =
                $aggregate_condition_id;
        }
        $formula_map->{aggregate_conditions} = $aggregate_condition_map;

        # register aggregate rule
        foreach my $old_agg_rule (@{ $service_provider->{aggregate_rules} }) {
            my $agg_rule_formula =  $old_agg_rule->{aggregate_rule_formula};
            $agg_rule_formula =~ s/id(\d+)/id$formula_map->{aggregate_conditions}->{$1}/g;

            Entity::Rule::AggregateRule->new(
                rule_name           => $old_agg_rule->{aggregate_rule_label},
                state               => $old_agg_rule->{aggregate_rule_state},
                description         => $old_agg_rule->{aggregate_rule_description},
                formula             => $agg_rule_formula,
                formula_string      => $old_agg_rule->{aggregate_rule_formula_string},
                service_provider_id => $new_externalcluster->id,
            );
        }

        # register nodemetric conditions
        foreach my $old_nodemetric_condition (@{ $service_provider->{nodemetric_conditions} }) {
            my $left_combination_id = $combination_map->{ $old_nodemetric_condition->{left_combination_id} };
            my $right_combination_id = $combination_map->{ $old_nodemetric_condition->{right_combination_id} };
            my $nodemetric_condition_id = Entity::NodemetricCondition->new(
                nodemetric_condition_label               => $old_nodemetric_condition->{nodemetric_condition_label},
                nodemetric_condition_formula_string      => $old_nodemetric_condition->{nodemetric_condition_formula_string},
                nodemetric_condition_comparator          => $old_nodemetric_condition->{nodemetric_condition_comparator},
                left_combination_id                      => $left_combination_id,
                right_combination_id                     => $right_combination_id,
                nodemetric_condition_service_provider_id => $new_externalcluster->id,
            )->id;
            $nodemetric_condition_map->{ $old_nodemetric_condition->{nodemetric_condition_id} } =
                $nodemetric_condition_id;
        }
        $formula_map->{nodemetric_conditions} = $nodemetric_condition_map;

        # register aggregate rule
        foreach my $old_nodemetric_rule (@{ $service_provider->{nodemetric_rules} }) {
            my $nodemetric_rule_formula =  $old_nodemetric_rule->{nodemetric_rule_formula};
            $nodemetric_rule_formula =~ s/id(\d+)/id$formula_map->{nodemetric_conditions}->{$1}/g;

            Entity::Rule::NodemetricRule->new(
                rule_name           => $old_nodemetric_rule->{nodemetric_rule_label},
                state               => $old_nodemetric_rule->{nodemetric_rule_state},
                description         => $old_nodemetric_rule->{nodemetric_rule_description},
                formula             => $nodemetric_rule_formula,
                formula_string      => $old_nodemetric_rule->{nodemetric_rule_formula_string},
                service_provider_id => $new_externalcluster->id,
            );
        }
    }

    # restore monitoring data
    if (not -d $rrd_backup_dir) {
        throw  Kanopya::Exception::Internal(error => 'RRD backup directory not found');
    }
    else {
        # delete all rrd files in current install's rrd directory
        `$del_file $rrd_dir*.rrd`;

        # restore files with new clustermetric ids
        opendir(DIR, $rrd_backup_dir) or die $!;
        while (my $old_rrd_file = readdir(DIR)) {
            next unless (-f $rrd_backup_dir.$old_rrd_file);
            next unless ($old_rrd_file =~ m/^timeDB_(\d+)\.rrd$/);

            (my $rrd_file = $old_rrd_file) =~ s/timeDB_(\d+)/timeDB_$clustermetric_map->{$1}/;
            `$cp_file $rrd_backup_dir$old_rrd_file $rrd_dir$rrd_file`;
        }
        closedir(DIR);
    }

    # configure services
    my $configuration = $json_imported_items->{configuration};
    my $kanopya_cluster = Entity::ServiceProvider::Cluster->getKanopyaCluster();
    if (defined $configuration->{aggregator}) {
        $kanopya_cluster->getComponent(name => 'KanopyaAggregator')->setConf(
            conf => {
                time_step => $configuration->{aggregator}->{time_step},
                storage_duration => $configuration->{aggregator}->{storage_duration}->{duration},
            }
        );
    }

    if (defined $configuration->{orchestrator}) {
        $kanopya_cluster->getComponent(name => 'KanopyaRulesEngine')->setConf(
            conf => {
                time_step => $configuration->{orchestrator}->{time_step},
            }
        );
    }
}

1;
