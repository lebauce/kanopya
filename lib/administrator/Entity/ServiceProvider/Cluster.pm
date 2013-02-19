#    Copyright 2011 Hedera Technology SAS
#
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

=pod

=begin classdoc

This object allows to manipulate cluster configuration

=end classdoc

=cut

package Entity::ServiceProvider::Cluster;
use base 'Entity::ServiceProvider';

use strict;
use warnings;

use General;
use Node;
use Indicatorset;
use Collect;
use BillingManager;
use ServiceProviderManager;
use Entity::Component;
use Entity::Operation;
use Entity::Workflow;
use Entity::Clustermetric;
use Entity::Combination::NodemetricCombination;
use Entity::Combination::AggregateCombination;
use Entity::ServiceTemplate;
use Entity::Billinglimit;
use ClassType::ComponentType;
use Manager::HostManager;
use Kanopya::Config;

use Hash::Merge;
use DateTime;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    cluster_name => {
        label        => 'Instance name',
        pattern      => '^[\w\d\.]+$',
        is_mandatory => 1,
        is_editable  => 0
    },
    cluster_desc => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_editable  => 1
    },
    cluster_type => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0,
        is_editable  => 0
    },
    cluster_boot_policy => {
        label        => 'Boot policy',
        pattern      => '^.*$',
        is_mandatory => 0,
        is_editable  => 0
    },
    cluster_si_shared => {
        pattern      => '^(0|1)$',
        is_mandatory => 1,
        is_editable  => 0
    },
    cluster_si_persistent => {
        pattern      => '^(0|1)$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 0
    },
    cluster_min_node => {
        label        => 'Minimum number of nodes',
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    cluster_max_node => {
        label        => 'Maximum number of nodes',
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    cluster_priority => {
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    cluster_state => {
        label        => 'State',
        pattern      => '^up:\d*|down:\d*|starting:\d*|stopping:\d*|warning:\d*',
        is_mandatory => 0,
        is_editable  => 0
    },
    cluster_domainname => {
        label        => 'Domain',
        pattern      => '^[a-z0-9-]+(\.[a-z0-9-]+)+$',
        is_mandatory => 1,
        is_editable  => 0
    },
    cluster_nameserver1 => {
        label        => 'Primary name server',
        pattern      => '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$',
        is_mandatory => 1,
        is_editable  => 0
    },
    cluster_nameserver2 => {
        label        => 'Secondary name server',
        pattern      => '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$',
        is_mandatory => 1,
        is_editable  => 0
    },
    cluster_basehostname => {
        label        => 'Base host name',
        pattern      => '^[a-z_0-9-]+$',
        is_mandatory => 1,
        is_editable  => 1
    },
    default_gateway_id => {
        pattern      => '\d+',
        is_mandatory => 0,
        is_editable  => 1
    },
    active => {
        label        => 'Active',
        pattern      => '^[01]$',
        is_mandatory => 0,
        is_editable  => 0
    },
    masterimage_id => {
        label        => 'Master image',
        pattern      => '\d*',
        type         => 'relation',
        relation     => 'single',
        is_mandatory => 0,
        is_editable  => 0
    },
    kernel_id => {
        label        => 'Kernel',
        pattern      => '^\d*$',
        type         => 'relation',
        relation     => 'single',
        is_mandatory => 0,
        is_editable  => 1
    },
    user_id => {
        label        => 'Owner',
        pattern      => '^\d+$',
        type         => 'relation',
        relation     => 'single',
        is_mandatory => 1,
        is_editable  => 0
    },
    components => {
        label        => 'Components',
        type         => 'relation',
        relation     => 'single_multi',
        link_to      => 'component',
        is_mandatory => 0,
        is_editable  => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        addNode => {
            description => 'add a node to this cluster',
            perm_holder => 'entity',
        },
        removeNode => {
            description => 'remove a node from this cluster',
            perm_holder => 'entity',
        },
        activate => {
            description => 'activate this cluster',
            perm_holder => 'entity',
        },
        deactivate => {
            description => 'deactivate this cluster',
            perm_holder => 'entity',
        },
        start => {
            description => 'start this cluster',
            perm_holder => 'entity',
        },
        stop => {
            description => 'stop this cluster',
            perm_holder => 'entity',
        },
        forceStop => {
            description => 'force stop this cluster',
            perm_holder => 'entity',
        },
    };
}

=head2

    BaseDB label virtual attribute getter

=cut

sub label {
    my $self = shift;
    return $self->cluster_name;
}

=head2 create

    %params => {
        cluster_name     => 'foo',
        cluster_desc     => 'bar',
        cluster_min_node => 1,
        cluster_max_node => 10,
        masterimage_id   => 4,
        ...
        managers => {
            host_manager => {
                manager_id     => 2,
                manager_type   => 'HostManager',
                manager_params => {
                    cpu => 2,
                    ram => 1024,
                },
            },
            disk_manager => { ... },
        },
        policies => {
            hosting => 45,
            storage => 54,
            network => 32,
            ...
        },
        interfaces => {
            admin => {
                bonds_number => 2,
                interfaces_netconfs => [ 1, 5 ],
            }
        },
        components => {
            puppet => {
                component_type => 42,
            },
        },
    };

=cut

sub create {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, required => [ 'cluster_name', 'user_id' ]);

    # Override params with policies param presets
    my $merge = Hash::Merge->new('RIGHT_PRECEDENT');

    my $service_template;
    my $confpattern = {};

    # Prepare the configuration pattern from the service template and policies
    my @policies = defined $args{policies} ? delete $args{policies} : ();
    if (defined $args{service_template_id}) {
        $service_template = Entity::ServiceTemplate->get(id => $args{service_template_id});

        @policies = ( @{ $service_template->getPolicies }, @policies );
    }

    # Firstly translate possible flattened additional policy params to the
    # cluster configuration pattern format.
    #
    # Note that it is possible to give additional policy params in the flattened format
    # (see Policy.pm), only if the id of the policy that the params belongs to is specified.
    # Otherwise, params must be given in the cluster configuration pattern format.
    for my $policy (@policies) {
        $confpattern = $merge->merge($confpattern, $policy->getPattern(params => \%args));
    }

    # Then merge the configuration pattern with the remaining cluster params
    $confpattern = $merge->merge($confpattern, \%args);

    General::checkParams(args => $confpattern, required => [ 'managers' ]);
    General::checkParams(args => $confpattern->{managers}, required => [ 'host_manager', 'disk_manager' ]);

#    $log->debug("Final parameters after applying policies:\n" . Dumper($confpattern));

    my $composite_params;
    for my $name ('managers', 'interfaces', 'components', 'billing_limits', 'orchestration') {
        if ($confpattern->{$name}) {
            $composite_params->{$name} = delete $confpattern->{$name};
        }
    }

    $class->checkConfigurationPattern(attrs => $confpattern, composite => $composite_params);

    my $op_params = {
        cluster_params => $confpattern,
        presets        => $composite_params,
    };

    # If the cluster created from a service template, add it in the context
    # to handle notification/validation on cluster instanciation.
    if ($service_template) {
        $op_params->{context}->{service_template} = $service_template;
    }

    Entity::Operation->enqueue(
        priority => 200,
        type     => 'AddCluster',
        params   => $op_params
    );
}

sub checkConfigurationPattern {
    my $self = shift;
    my $class = ref($self) || $self;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'attrs' ]);

    # Firstly, check the cluster attrs
    $class->checkAttrs(attrs => $args{attrs});

    # Then check the configuration if required
    if (defined $args{composite}) {

        # For now, only check the manaher paramters only
        for my $manager_def (values %{ $args{composite}->{managers} }) {
            if (defined $manager_def->{manager_id}) {
                my $manager = Entity->get(id => $manager_def->{manager_id});

                $manager->checkManagerParams(manager_type   => $manager_def->{manager_type},
                                             manager_params => $manager_def->{manager_params});
            }
        }

        # TODO: Check cross managers dependencies. For example, the list of
        #       disk managers depend on the host manager.
    }
}

sub applyPolicies {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "presets" ]);

    # First, configure managers (potentially needed by other policies)
    if (exists $args{presets}{managers}) {
        $self->configureManagers(managers => $args{presets}{managers});
        delete $args{presets}{managers};
    }

    # Then, configure cluster using policies
    my ($name, $value);
    for my $name (keys %{ $args{presets} }) {
        $value = $args{presets}->{$name};

        # Handle components cluster config
        if ($name eq 'components') {
            for my $component (values %$value) {
                # TODO: Check if the component is already installed
                my $instance = $self->addComponentFromType(
                    component_type_id       => $component->{component_type},
                    component_configuration => $component->{component_configuration}
                );
                # Insert default configuration for tables linked to component (when exists)
                $instance->insertDefaultExtendedConfiguration();
            }
        }
        # Handle network interfaces cluster config
        elsif ($name eq 'interfaces') {
            $self->configureInterfaces(interfaces => $value);
        }
        elsif ($name eq 'billing_limits') {
            $self->configureBillingLimits(billing_limits => $value);
        }
        elsif ($name eq 'orchestration') {
            $self->configureOrchestration(%$value);
        }
        else {
            $self->setAttr(name => $name, value => $value);
        }
    }
    $self->save();
}

sub configureManagers {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, optional => { 'managers' => undef });

    my $kanopya = Entity->get(id => Kanopya::Config::get("executor")->{cluster}->{executor});

    # Install new managers or/and new managers params if required
    if (defined $args{managers}) {
        # Add default workflow manager
        my $workflow_manager = $kanopya->getComponent(name => "Kanopyaworkflow", version => "0");
        $args{managers}->{workflow_manager} = { manager_id   => $workflow_manager->id,
                                                manager_type => "WorkflowManager" };

        # Add default collector manager
        my $collector_manager = $kanopya->getComponent(name => "Kanopyacollector", version => "1");
        $args{managers}->{collector_manager} = { manager_id   => $collector_manager->id,
                                                 manager_type => "CollectorManager" };

        for my $manager (values %{$args{managers}}) {
            # Check if the manager is already set, add it otherwise,
            # and set manager parameters if defined.
            eval {
                ServiceProviderManager->find(
                    hash   => { service_provider_id => $self->id },
                    custom => { category => $manager->{manager_type} },
                );
            };
            if ($@) {
                next if not $manager->{manager_id};
                $self->addManager(manager_id   => $manager->{manager_id},
                                  manager_type => $manager->{manager_type});

                if ($manager->{manager_type} eq 'CollectorManager') {
                    $self->initCollectorManager(collector_manager => Entity->get(id => $manager->{manager_id}));
                }
            }

            if ($manager->{manager_params}) {
                $self->addManagerParameters(manager_type => $manager->{manager_type},
                                            params       => $manager->{manager_params},
                                            override     => 1);
            }
        }
    }

    my $disk_manager   = $self->getManager(manager_type => 'DiskManager');
    my $export_manager = eval { $self->getManager(manager_type => 'ExportManager') };

    # If the export manager exists, deduce the boot policy
    if(not ($export_manager and $self->cluster_boot_policy)) {
        if ($export_manager) {
            my $bootpolicy = $disk_manager->getBootPolicyFromExportManager(export_manager => $export_manager);
            $self->setAttr(name => 'cluster_boot_policy', value => $bootpolicy);
            $self->save();
        }
        # Else use the boot policy to deduce the export manager to use
        else {
            $export_manager = $disk_manager->getExportManagerFromBootPolicy(
                                  boot_policy => $self->cluster_boot_policy
                              );

            $self->addManager(manager_id => $export_manager->id, manager_type => "ExportManager");
        }
    }
    
    if ($self->cluster_boot_policy eq Manager::HostManager->BOOT_POLICIES->{pxe_iscsi}) {
        $self->addComponentFromType(
            component_type_id => ClassType::ComponentType->find(hash => { component_name => "Openiscsi" })->id
        );
    }

    # Get export manager parameter related to si shared value.
    my $readonly_param = $export_manager->getReadOnlyParameter(
                             readonly => $self->cluster_si_shared
                         );

    # TODO: This will be usefull for the first call to applyPolicies at the cluster creation,
    #       but there will be export manager params consitency problem if policies are updated.
    if ($readonly_param) {
        $self->addManagerParameter(
            manager_type => 'ExportManager',
            name         => $readonly_param->{name},
            value        => $readonly_param->{value}
        );
    }
}

sub configureInterfaces {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { 'interfaces' => undef });

    if (defined $args{interfaces}) {
        for my $interface_pattern (values %{ $args{interfaces} }) {
            if ($interface_pattern->{interface_netconfs}) {
                # TODO: Search among existing interfaces to avoid to re-create its.

                my $bonds_number = $interface_pattern->{bonds_number};
                $bonds_number = defined $bonds_number ? $bonds_number : 0;

                my @netconfs = values %{ $interface_pattern->{interface_netconfs} };
                $self->addNetworkInterface(netconfs     => \@netconfs,
                                           bonds_number => $bonds_number);
            }
        }
    }
}

sub configureBillingLimits {
    my $self    = shift;
    my %args    = @_;

    General::checkParams(args => \%args, optional => { 'billing_limits' => undef });

    if (defined($args{billing_limits})) {
        foreach my $name (keys %{$args{billing_limits}}) {
            my $value = $args{billing_limits}->{$name};
            Entity::Billinglimit->new(
                start               => $value->{start},
                ending              => $value->{ending},
                type                => $value->{type},
                soft                => $value->{soft},
                service_provider_id => $self->getAttr(name => 'entity_id'),
                repeats             => $value->{repeats},
                repeat_start_time   => $value->{repeat_start_time},
                repeat_end_time     => $value->{repeat_end_time},
                value               => $value->{value}
            );
        }

        my @indicators = qw(Memory Cores);
        foreach my $name (@indicators) {
            my $indicator = Indicator->find(hash => { indicator_name => $name });

            my $cm = Entity::Clustermetric->new(
                clustermetric_label                    => "Billing" . $name,
                clustermetric_service_provider_id      => $self->getId,
                clustermetric_indicator_id             => $indicator->getId,
                clustermetric_statistics_function_name => "sum",
                clustermetric_window_time              => '1200',
            );

            Entity::Combination::AggregateCombination->new(
                aggregate_combination_label     => "Billing" . $name,
                service_provider_id             => $self->getId,
                aggregate_combination_formula   => 'id' . $cm->getId
            );
        }
    }
}

=head2 configureOrchestration

    desc :
        Use the linked policy service provider and clone its orchestration data in $self

=cut

sub configureOrchestration {
    my $self    = shift;
    my %args    = @_;

    return if (not defined $args{service_provider_id});

    my $sp = Entity::ServiceProvider->get(id => $args{service_provider_id});

    for (
        $sp->clustermetrics,
        $sp->combinations,
        $sp->nodemetric_conditions,
        $sp->aggregate_conditions,
        $sp->nodemetric_rules,
        $sp->aggregate_rules
        ) {
        $_->clone(dest_service_provider_id => $self->id);
    }
}

=head2 remove

=cut

sub remove {
    my $self = shift;

    $log->debug("New Operation Remove Cluster with cluster id : " .  $self->id);
    Entity::Operation->enqueue(
        priority => 200,
        type     => 'RemoveCluster',
        params   => {
            context => {
                cluster => $self,
            },
        },
    );
}

sub forceStop {
    my $self = shift;

    $log->debug("New Operation Force Stop Cluster with cluster: " . $self->id);
    Entity::Operation->enqueue(
        priority => 200,
        type     => 'ForceStopCluster',
        params   => {
            context => {
                cluster => $self,
            },
        },
    );
}

sub activate {
    my $self = shift;

    $log->debug("New Operation ActivateCluster with cluster_id : " . $self->id);
    Entity::Operation->enqueue(
        priority => 200,
        type     => 'ActivateCluster',
        params   => {
            context => {
                cluster => $self,
            },
        },
    );
}

sub deactivate {
    my $self = shift;

    $log->debug("New Operation DeactivateCluster with cluster_id : " . $self->id);
    Entity::Operation->enqueue(
        priority => 200,
        type     => 'DeactivateCluster',
        params   => {
            context => {
                cluster => $self,
            },
        },
    );
}

=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;
    my $string = $self->{_dbix}->get_column('cluster_name');
    return $string.' (Cluster)';
}


=pod

=begin classdoc

Override the parent method to set permission on the component to
the cluster customer.

@return the added component

=end classdoc

=cut

sub addComponent {
    my ($self, %args) = @_;

    my $component = $self->SUPER::addComponent(%args);
    for my $method ('getConf', 'setConf') {
        $component->addPerm(consumer => $self->user, method => $method);
    }
    return $component;
}

sub getMasterNode {
    my $self = shift;
    my $masternode;

    eval {
        $masternode = Node->find(hash => {
                          service_provider_id => $self->id,
                          master_node         => 1
                      });
    };
    if ($@) {
        return undef;
    }

    return $masternode->host;
}

sub getMasterNodeIp {
    my $self = shift;
    my $master;

    $master = $self->getMasterNode();
    if (defined ($master)) {
        return $master->adminIp;
    }

    return;
}

sub getMasterNodeFQDN {
    my $self = shift;

    return $self->getMasterNode()->node->node_hostname . '.' . $self->cluster_domainname;
}

sub getMasterNodeId {
    my $self = shift;
    my $host = $self->getMasterNode;

    if (defined ($host)) {
        return $host->id;
    }

    return;
}

sub getMasterNodeSystemimage {
    my $self = shift;

    my $node = $self->findRelated(filters => ['nodes'], hash => { master_node => 1 });

    return $node->systemimage;
}


sub getHosts {
    my ($self) = @_;

    my @hosts = map { $_->host } $self->nodes;
    return wantarray ? @hosts : \@hosts;
}

=head2 getHostManager

    desc: Return the component/conector that manage this cluster.

=cut

sub getHostManager {
    my $self = shift;

    return $self->getManager(manager_type => 'HostManager');
}

=head2 getCurrentNodesCount

    class : public
    desc : return the current nodes count of the cluster

=cut

sub getCurrentNodesCount {
    my $self = shift;
    my $nodes = $self->{_dbix}->parent->nodes;
    if ($nodes) {
    return $nodes->count;}
    else {
        return 0;
    }
}

=head2 getQoSConstraints

    Class : Public

    Desc :

=cut

sub getQoSConstraints {
    my $self = shift;
    my %args = @_;

    # TODO retrieve from db (it's currently done by RulesManager, move here)
    return { max_latency => 22, max_abort_rate => 0.3 } ;
}

sub isLoadBalanced {
    my $self = shift;

    # search for an potential 'loadbalanced' component
    my $cluster_components = $self->getComponents(category => "all");
    my $is_loadbalanced = 0;
    foreach my $component (@{ $cluster_components }) {
        my $clusterization_type = $component->getClusterizationType();
        if ($clusterization_type && ($clusterization_type eq 'loadbalanced')) {
            $is_loadbalanced = 1;
            last;
        }
    }

    return $is_loadbalanced;
}

=head2 addNode

=cut

sub addNode {
    my $self = shift;

    return Entity::Workflow->run(
        name       => 'AddNode',
        related_id => $self->id,
        params     => {
            context => {
                cluster => $self,
            }
        }
    );
}

=head2 removeNode

=cut

sub removeNode {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['host_id']);

    my $host = Entity->get(id => $args{host_id});
    Entity::Workflow->run(
        name       => 'StopNode',
        related_id => $self->id,
        params     => {
            context => {
                cluster => $self,
                host    => $host,
            }
        }
     );
}

=head2 start

=cut

sub start {
    my $self = shift;

    $self->setState(state => 'starting');

    # Enqueue operation AddNode.
    return $self->addNode();
}

=head2 stop

=cut

sub stop {
    my $self = shift;

    $log->debug("New Operation StopCluster with cluster_id : " . $self->id);
    return Entity::Operation->enqueue(
        priority => 200,
        type     => 'StopCluster',
        params   => {
            context => {
                cluster => $self,
            }
        },
    );
}

=head2 getState

=cut

sub getState {
    my $self = shift;
    my $state = $self->cluster_state;
    return wantarray ? split(/:/, $state) : $state;
}

=head2 setState

=cut

sub setState {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'state' ]);

    $self->setAttr(name => 'cluster_prev_state', value => $self->getState());
    $self->setAttr(name => 'cluster_state', value => $args{state} . ":" . time);
    $self->save();
}


sub getNewNodeNumber {
    my $self = shift;
    my @nodes = $self->getHosts();

    # if no nodes already registered, number is 1
    if (scalar(@nodes) <= 0) { return 1; }

    my @current_nodes_number = ();
    for my $host (@nodes) {
        push @current_nodes_number, $host->getNodeNumber();
    }

    # http://rosettacode.org/wiki/Sort_an_integer_array#Perl
    @current_nodes_number =  sort {$a <=> $b} @current_nodes_number;

    my $counter = 1;
    for my $number (@current_nodes_number) {
        if ("$counter" eq "$number") {
            $counter += 1;
            next;
        } else {
            return $counter;
        }
    }

    return $counter;
}

=head2 getNodesMetrics

    Desc: call collector manager to retrieve nodes metrics values.
    return \%data;

=cut

sub getNodesMetrics {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'time_span', 'indicators' ]);

    my $collector_manager = $self->getManager(manager_type => "CollectorManager");
    my $mparams           = $self->getManagerParameters(manager_type => 'CollectorManager');

    my @nodelist;
    for my $host (@{ $self->getHosts() }) {
        push @nodelist, $host->node->node_hostname;
    }

    return $collector_manager->retrieveData(
               nodelist   => \@nodelist,
               time_span  => $args{'time_span'},
               indicators => $args{'indicators'},
               %$mparams
           );
}

sub generateOverLoadNodemetricRules {
    my ($self, %args) = @_;
    my $service_provider_id = $self->getId();

    my $creation_conf = {
        'memory' => {
             formula         => 'id2 / id1',
             comparator      => '>',
             threshold       => 70,
             rule_label      => '%MEM used too high',
             rule_description => 'Percentage memory used is too high',
        },
        'cpu' => {
            #User+Idle+Wait+Nice+Syst+Kernel+Interrupt
             formula         => '(id5 + id6 + id7 + id8 + id9 + id10) / (id5 + id6 + id7 + id8 + id9 + id10 + id11)',
             comparator      => '>',
             threshold       => 70,
             rule_label      => '%CPU used too high',
             rule_description => 'Percentage processor used is too high',
        },
    };

    while (  my ($key, $value) = each(%$creation_conf) ) {
        my $combination_param = {
            nodemetric_combination_formula  => $value->{formula},
            service_provider_id             => $service_provider_id,
        };

        my $comb  = Entity::Combination::NodemetricCombination->new(%$combination_param);

        my $condition_param = {
            left_combination_id      => $comb->getAttr(name=>'nodemetric_combination_id'),
            nodemetric_condition_comparator          => $value->{comparator},
            nodemetric_condition_threshold           => $value->{threshold},
            nodemetric_condition_service_provider_id => $service_provider_id,
        };

        my $condition = Entity::NodemetricCondition->new(%$condition_param);
        my $conditionid = $condition->getAttr(name => 'nodemetric_condition_id');
        my $prule = {
            nodemetric_rule_formula             => 'id'.$conditionid,
            nodemetric_rule_label               => $value->{rule_label},
            nodemetric_rule_description         => $value->{rule_description},
            nodemetric_rule_state               => 'enabled',
            nodemetric_rule_service_provider_id => $service_provider_id,
        };
        Entity::Rule::NodemetricRule->new(%$prule);
    }
}

=head2 generateDefaultMonitoringConfiguration

    Desc: create default nodemetric combination and clustermetric for the service provider

=cut


sub generateDefaultMonitoringConfiguration {
    my ($self, %args) = @_;

    my $indicators = $self->getManager(manager_type => "CollectorManager")->getIndicators();
    my $service_provider_id = $self->getId;

    # We create a nodemetric combination for each indicator
    foreach my $indicator (@$indicators) {
        my $combination_param = {
            nodemetric_combination_formula  => 'id' . $indicator->getId,
            service_provider_id             => $service_provider_id,
        };
        Entity::Combination::NodemetricCombination->new(%$combination_param);
    }

    #definition of the functions
    my @funcs = qw(mean max min std dataOut);

    #we create the clustermetric and associate combination
    foreach my $indicator (@$indicators) {
        foreach my $func (@funcs) {
            my $cm_params = {
                clustermetric_service_provider_id      => $service_provider_id,
                clustermetric_indicator_id             => $indicator->getId,
                clustermetric_statistics_function_name => $func,
                clustermetric_window_time              => '1200',
            };
            my $cm = Entity::Clustermetric->new(%$cm_params);

            my $acf_params = {
                service_provider_id             => $service_provider_id,
                aggregate_combination_formula   => 'id' . $cm->getId
            };
            my $clustermetric_combination = Entity::Combination::AggregateCombination->new(%$acf_params);
        }
    }
}

=head2 initCollectorManager

    desc: initialize the collect for the native kanopya collector indicatorsets
    Args: object $collector_manager
    Return: none

=cut

sub initCollectorManager {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'collector_manager' ]);

    my @indicatorsets = Indicatorset->search(hash => {});

    foreach my $indicatorset (@indicatorsets) {
        if ($indicatorset->indicatorset_provider eq 'SnmpProvider' ||
            $indicatorset->indicatorset_provider eq 'KanopyaDatabaseProvider') {
            Collect->create(
                service_provider_id => $self->id,
                indicatorset_id     => $indicatorset->indicatorset_id
            );
        }
    }
}

=head2 getMonthlyConsommation

=cut

sub getMonthlyConsommation {
    my $self = shift;

    my ($from, $to);

    $to   = DateTime->now;
    $from = DateTime->new(
                year        => $to->year,
                month       => $to->month,
                day         => 1,
                hour        => 0,
                minute      => 0,
                second      => 0,
                nanosecond  => 0,
                time_zone   => $to->time_zone
            );

    BillingManager::clusterBilling($self->user, $self, $from, $to, 1);
}

sub lock {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'consumer' ]);

    # Lock the cluster himself
    $self->SUPER::lock(%args);

    # Lock the customer user related to the cluster
    $self->user->lock(%args);
}

sub unlock {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'consumer' ]);

    # Unock the customer user related to the cluster
    $self->user->unlock(%args);

    # Unlock the cluster himself
    $self->SUPER::unlock(%args);
}

sub update {
    my $self = shift;
    my %args = @_;

    if (defined ($args{components})) {
        for my $component (@{$args{components}}) {
            $self->addComponentFromType(component_type_id => $component->{component_type_id});
        }
        delete $args{components};

        Entity::Operation->enqueue(
            priority => 200,
            type     => 'UpdatePuppetCluster',
            params   => {
                context => {
                    cluster => $self,
                },
            },
        );
    }
}


1;
