# Cluster.pm - This object allows to manipulate cluster configuration
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

=pod

=begin classdoc

This object allows to manipulate cluster configuration

=end classdoc

=cut

package Entity::ServiceProvider::Inside::Cluster;
use base 'Entity::ServiceProvider::Inside';

use strict;
use warnings;
use Kanopya::Exceptions;
use Kanopya::Config;
use Entity::Component;
use Entity::Host;
use Externalnode::Node;
use Entity::Systemimage;
use Externalnode::Node;
use Entity::Operation;
use Entity::Workflow;
use Entity::Combination::NodemetricCombination;
use Entity::Clustermetric;
use Entity::Combination::AggregateCombination;
use Entity::Policy;
use Administrator;
use General;
use ServiceProviderManager;
use Entity::ServiceTemplate;
use VerifiedNoderule;
use Entity::Indicator;
use Indicatorset;
use Entity::Billinglimit;
use Entity::Component::Kanopyaworkflow0;
use Entity::Component::Kanopyacollector1;
use BillingManager;
use ComponentType;
use Manager::HostManager;

use Hash::Merge;
use DateTime;

use Log::Log4perl "get_logger";
use Data::Dumper;

our $VERSION = "1.00";

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
                manager_type   => 'host_manager',
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

    $log->debug("Final parameters after applying policies:\n" . Dumper($confpattern));

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

    # Workaround to handle connectors that have both category.
    # We need to fix this when we will merge inside/outside.
    my $wok_disk_manager   = $args{managers}->{disk_manager}->{manager_id};
    my $wok_export_manager = $args{managers}->{export_manager}->{manager_id};
    if ($wok_disk_manager and $wok_export_manager) {
        if ($wok_disk_manager != $kanopya->getComponent(name => "Lvm", version => "2")->id and
            $wok_disk_manager != $kanopya->getComponent(name => "Storage")->id) {
            $args{managers}->{export_manager}->{manager_id} = $wok_disk_manager;
        }
    }

    # Install new managers or/and new managers params if required
    if (defined $args{managers}) {
        # Add default workflow manager
        my $workflow_manager = $kanopya->getComponent(name => "Kanopyaworkflow", version => "0");
        $args{managers}->{workflow_manager} = {
            manager_id   => $workflow_manager->id,
            manager_type => "workflow_manager"
        };

        # Add default collector manager
        my $collector_manager = $kanopya->getComponent(name => "Kanopyacollector", version => "1");
        $args{managers}->{collector_manager} = {
            manager_id   => $collector_manager->id,
            manager_type => "collector_manager"
        };

        for my $manager (values %{$args{managers}}) {
            # Check if the manager is already set, add it otherwise,
            # and set manager parameters if defined.
            eval {
                ServiceProviderManager->find(hash => { manager_type        => $manager->{manager_type},
                                                       service_provider_id => $self->id });
            };
            if ($@) {
                next if not $manager->{manager_id};
                $self->addManager(manager_id   => $manager->{manager_id},
                                  manager_type => $manager->{manager_type});

                if ($manager->{manager_type} eq 'collector_manager') {
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

    my $disk_manager   = $self->getManager(manager_type => 'disk_manager');
    my $export_manager = eval { $self->getManager(manager_type => 'export_manager') };

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

            $self->addManager(manager_id => $export_manager->id, manager_type => "export_manager");
        }
    }
    
    if ($self->cluster_boot_policy eq Manager::HostManager->BOOT_POLICIES->{pxe_iscsi}) {
        $self->addComponentFromType(
            component_type_id => ComponentType->find(hash => { component_name => "Openiscsi" })->id
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
            manager_type => 'export_manager',
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

    # Node metrics
    my @nodemetriccombinations = $sp->nodemetric_combinations;
    for my $nmc (@nodemetriccombinations) {
        my %attrs = $nmc->getAttrs();
        delete $attrs{nodemetric_combination_id};

        $attrs{service_provider_id} = $self->getId();
        Entity::Combination::NodemetricCombination->new( %attrs );
    }

    # Cluster metrics and combinations
    $self->_cloneOrchestrationCompositeData(
        from            => $sp,
        elem_name       => 'clustermetric',
        composite_name  => 'aggregate_combination',
    );

    # Node conditions and rules
    $self->_cloneOrchestrationCompositeData(
        from            => $sp,
        elem_name       => 'nodemetric_condition',
        composite_name  => 'nodemetric_rule',
    );

    # Cluster conditions and rules
    $self->_cloneOrchestrationCompositeData(
        from            => $sp,
        elem_name       => 'aggregate_condition',
        composite_name  => 'aggregate_rule',
    );

    # Associate workflows to rules (clone workflows)
    # Workflow_def associated to the rule is the same than the policy
    # So we clone it and associate the new one to the rule to keep 1 <-> 1 relationship
    my $workflow_manager = $self->getManager( manager_type => 'workflow_manager');
    for my $rule ($self->nodemetric_rules, $self->aggregate_rules) {
        my $rule_id    = $rule->id;
        my $wf_id      = $rule->workflow_def_id; # The wf id from the policy
        if ($wf_id) {
            # Get original workflow def and params (from policy)
            my $wf_def      = $rule->workflow_def;
            my $wf_params   = $wf_def->paramPresets;
            my $wf_name     = $wf_def->workflow_def_name;

            # Replacing in workflow name the id of original rule (from policy) with id of this rule
            # TODO change associated workflow naming convention (currently: <ruleid>_<origin_wf_def_name>) UGLY!
            $wf_name =~ s/^[0-9]*/$rule_id/;

            # Associate to the rule a copy of the policy workflow
            $workflow_manager->associateWorkflow(
                'new_workflow_name'         => $wf_name,
                'origin_workflow_def_id'    => $wf_def->workflow_def_origin,
                'specific_params'           => $wf_params->{specific} || {},
                'rule_id'                   => $rule_id,
            );
        }
    }
}

=head2 remove

=cut

sub remove {
    my $self = shift;
    my $adm = Administrator->new();

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

=head2 getComponents

    Desc : This function get components used in a cluster. This function allows to select
            category of components or all of them.
    args:
        category : String : Component category

    return : a hashref of components, it is indexed on component_instance_id

=cut

sub getComponents {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'category' ],
                                         optional => { order_by => undef } );

    my $hash = { 'service_provider_id' => $self->id };

    if (defined ($args{category}) and $args{category} ne "all") {
        $hash->{'component_type.component_category'} = $args{category};
    };

    my @components = Entity::Component->search(hash => $hash);

    if (defined ($args{order_by})) {
        my $criteria = $args{order_by};
        @components = sort { $a->$criteria <=> $b->$criteria } @components;
    }

    return wantarray ? @components : \@components;
}

=head2 getComponent

    Desc : This function get component used in a cluster. This function allows to select
            a particular component with its name and version.
    args:
        administrator : Administrator : Administrator object to instanciate all components
        name : String : Component name
        version : String : Component version
    return : a component instance

=cut

sub getComponent {
    my ($self, %args) = @_;

    General::checkParams(args => \%args);

    my $hash = { 'service_provider_id' => $self->id };

    if (defined ($args{name})) {
        $hash->{'component_type.component_name'} = $args{name};
    }

    if (defined ($args{category})) {
        $hash->{'component_type.component_category'} = $args{category};
    }

    if (defined ($args{version})) {
        $hash->{'component_type.component_version'} = $args{version};
    }

    return Entity::Component->find(hash => $hash);
}

sub getMasterNode {
    my $self = shift;
    my $masternode;

    eval {
        $masternode = Externalnode::Node->find(hash => {
                          inside_id   => $self->id,
                          master_node => 1
                      } );
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

sub getMasterNodeSystemimage {
    my $self = shift;
    my $node_instance_rs = $self->{_dbix}->parent->search_related(
                               "nodes", { master_node => 1 }
                           )->single;

    if(defined $node_instance_rs) {
        return Entity::Systemimage->get(id => $node_instance_rs->get_column('systemimage_id'));
    }
}

=head2 getHosts

    Desc : This function get hosts executing the cluster.
    args:
        administrator : Administrator : Administrator object to instanciate all components
    return : a hashref of host, it is indexed on host_id

=cut

sub getHosts {
    my ($self) = @_;

    my @hosts = map { $_->host } $self->nodes;
    return wantarray ? @hosts : \@hosts;
}

=head2 getHostEntries

    Desc : This function returns all the host entries (ip, fqdn, aliases)
           for a cluster.
    return : a list of hashref

=cut

sub getHostEntries {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { "components" => undef });

    my $executor = Entity->get(id => Kanopya::Config::get("executor")->{cluster}->{executor});
    my @host_entries;

    # we add each nodes
    foreach my $node ($self->getHosts()) {
        push @host_entries, {
            fqdn    => $node->fqdn,
            aliases => [ $node->host_hostname . "." . $executor->cluster_domainname,
                         $node->host_hostname ],
            ip      => $node->adminIp
        };
    }

    if ($args{components}) {
        # we ask components for additional hosts entries
        my @components = $self->getComponents(category => 'all');
        foreach my $component (@components) {
            my $entries = $component->getHostsEntries();
            if (defined $entries) {
                foreach my $entry (@$entries) {
                    push @host_entries, $entry;
                }
            }
        }
    }

    return @host_entries;
}

=head2 getHostManager

    desc: Return the component/conector that manage this cluster.

=cut

sub getHostManager {
    my $self = shift;

    return $self->getManager(manager_type => 'host_manager');
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
    $log->debug("Nodes number sorted: " . Dumper(@current_nodes_number));

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

=head2 _cloneOrchestrationCompositeData

    desc :
        clone all <elems> from service provider <from> and add it to $self
        do the same with <composites>
        A composite has a formula build with elems id,
        this formula is translated during cloning according to cloned elems ids

=cut

sub _cloneOrchestrationCompositeData {
    my $self    = shift;
    my %args    = @_;

    my $elem_name   = $args{elem_name};
    my $elem_class  = BaseDB::normalizeName($elem_name);
    my $comp_name   = $args{composite_name};
    my $comp_class  = BaseDB::normalizeName($comp_name);

    my %id_mapper;
    my $relationship;

    $relationship = $elem_name . 's';
    my @elems = $args{from}->$relationship;
    for my $elem (@elems) {
        my %attrs = $elem->getAttrs();
        my $elem_id = delete $attrs{ $elem_name . '_id'};
        $attrs{ $elem_name . '_service_provider_id' } = $self->getId();
        my $clone_elem = $elem_class->new( %attrs );
        $id_mapper{ $elem_id } = $clone_elem->getId();
    }

    $relationship = $comp_name . 's';
    my @composites = $args{from}->$relationship;
    for my $comp (@composites) {
        my %attrs = $comp->getAttrs();
        delete $attrs{ $comp_name . '_id'};
        $attrs{ $comp_name . '_service_provider_id' } = $self->getId();
        $attrs{ $comp_name . '_formula' } = $self->_translateFormula(
            formula => $attrs{ $comp_name . '_formula' },
            id_map  => \%id_mapper,
        );
        $comp_class->new( %attrs );
    }
}

=head2 _translateFormula

    desc : replaces id of a formula (used for metrics and rules) using an id translation map

=cut

sub _translateFormula {
    my $self    = shift;
    my %args    = @_;

    my $formula = $args{formula};
    my $id_map  = $args{id_map};

    # Split id from formula
    my @array = split(/(id\d+)/, $formula);
    # replace each id by its translation id
    for my $element (@array) {
        if( $element =~ m/id(\d+)/)
        {
            $element = 'id' . $id_map->{$1};
        }
    }
    return join('',@array);
}

=head2 getNodesMetrics

    Desc: call collector manager to retrieve nodes metrics values.
    return \%data;

=cut

sub getNodesMetrics {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'time_span', 'indicators' ]);

    my $collector_manager = $self->getManager(manager_type => "collector_manager");
    my $mparams           = $self->getManagerParameters(manager_type => 'collector_manager');

    my @nodelist;
    for my $host (@{ $self->getHosts() }) {
        push @nodelist, $host->host_hostname;
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

    my $indicators = $self->getManager(manager_type => "collector_manager")->getIndicators();
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

    my @indicatorsets = Indicatorset->search (hash => {});

    foreach my $indicatorset (@indicatorsets) {
        if ($indicatorset->indicatorset_provider eq 'SnmpProvider' ||
            $indicatorset->indicatorset_provider eq 'KanopyaDatabaseProvider') {
            eval {
                my $adm = Administrator->new();
                $adm->{db}->resultset('Collect')->create({
                    cluster_id      => $self->getId,
                    indicatorset_id => $indicatorset->indicatorset_id
                });
            };
        }
    }
}

=head2 getMonthlyConsommation

=cut

sub getMonthlyConsommation {
    my $self    = shift;

    my ($from, $to);

    $to         = DateTime->now;
    $from       = DateTime->new(
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
