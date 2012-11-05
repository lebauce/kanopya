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

use Hash::Merge;
use DateTime;

use Log::Log4perl "get_logger";
use Data::Dumper;

our $VERSION = "1.00";

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    cluster_name => {
        pattern      => '^[\w\d]+$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 0
    },
    cluster_desc => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0,
        is_editable  => 1
    },
    cluster_type => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0,
        is_editable  => 0
    },
    cluster_boot_policy => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0,
        is_editable  => 0
    },
    cluster_si_shared => {
        pattern      => '^(0|1)$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 0
    },
    cluster_si_persistent => {
        pattern      => '^(0|1)$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 0
    },
    cluster_min_node => {
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 1
    },
    cluster_max_node => {
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 1
    },
    cluster_priority => {
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 1
    },
    cluster_state => {
        pattern      => '^up:\d*|down:\d*|starting:\d*|stopping:\d*|warning:\d*',
        is_mandatory => 0,
        is_extended  => 0,
        is_editable  => 0
    },
    cluster_domainname => {
        pattern      => '^[a-z0-9-]+(\.[a-z0-9-]+)+$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 0
    },
    cluster_nameserver1 => {
        pattern      => '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 0
    },
    cluster_nameserver2 => {
        pattern      => '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 0
    },
    cluster_basehostname => {
        pattern      => '^[a-z_0-9-]+$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 1
    },
    active => {
        pattern      => '^[01]$',
        is_mandatory => 0,
        is_extended  => 0,
        is_editable  => 0
    },
    masterimage_id => {
        pattern      => '\d*',
        is_mandatory => 0,
        is_extended  => 0,
        is_editable  => 0
    },
    kernel_id => {
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_extended  => 0,
        is_editable  => 1
    },
	user_id => {
        pattern      => '^\d+$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        create => {
            description => 'create a new cluster',
            perm_holder => 'mastergroup',
        },
        get => {
            description => 'view this cluster',
            perm_holder => 'entity',
        },
        update => {
            description => 'save changes applied on this cluster',
            perm_holder => 'entity',
        },
        remove => {
            description => 'delete this cluster',
            perm_holder => 'entity',
        },
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
        setperm => {
            description => 'set permissions on this cluster',
            perm_holder => 'entity',
        },
        addComponent => {
            description => 'add a component to this cluster',
            perm_holder => 'entity',
        },
        removeComponent => {
            description => 'remove a component from this cluster',
            perm_holder => 'entity',
        },
        configureComponents => {
            description => 'configure components of this cluster',
            perm_holder => 'entity',
        },
    };
}

=head2 getClusters

=cut

sub getClusters {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['hash']);

    return $class->search(%args);
}

sub getCluster {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['hash']);

    my @clusters = $class->search(%args);
    return pop @clusters;
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
                interface_role => 'admin',
                interfaces_networks => [ 1 ],
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
    my ($class, %params) = @_;

    # Override params with poliies param presets
    my $merge = Hash::Merge->new('RIGHT_PRECEDENT');

    # Prepare the configuration pattern from the service template
    my $service_template;
    if (defined $params{service_template_id}) {
        # ui related, we get the completed values as flatened values from the form
        # so we need to transform all the flatened params to a configuration pattern.
        my %flatened_params = %params;
        %params = ();

        $service_template = Entity::ServiceTemplate->get(id => $flatened_params{service_template_id});
        for my $policy (@{ $service_template->getPolicies }) {
            # Register policy ids in the params
            push @{ $params{policies} }, $policy->getAttr(name => 'policy_id');

            # Rebuild params as a configuration pattern
            my $pattern = Entity::Policy->buildPatternFromHash(policy_type => $policy->getAttr(name => 'policy_type'), hash => \%flatened_params);
            %params = %{ $merge->merge(\%params, \%$pattern) };
        }
    }

    General::checkParams(args => \%params, required => [ 'managers' ]);
    General::checkParams(args => $params{managers}, required => [ 'host_manager', 'disk_manager' ]);

    # Firstly apply the policies presets on the cluster creation paramters.
    for my $policy_id (@{ $params{policies} }) {
        my $policy = Entity::Policy->get(id => $policy_id);

        # Load params preset into hash
        my $policy_presets = $policy->getParamPreset->load();

        # Merge current polciy preset with others
        %params = %{ $merge->merge(\%params, \%$policy_presets) };
    }

    delete $params{policies};

    $log->debug("Final parameters after applying policies:\n" . Dumper(%params));

    my %composite_params;
    for my $name ('managers', 'interfaces', 'components', 'billing_limits', 'orchestration') {
        if ($params{$name}) {
            $composite_params{$name} = delete $params{$name};
        }
    }

    $class->checkConfigurationPattern(attrs => \%params, composite => \%composite_params);

    my $op_params = {
        cluster_params => \%params,
        presets        => \%composite_params,
    };

    # If hte cluster created from a service template, add it in the context
    # to handle notification/validation on cluster instanciation.
    if ($service_template) {
        $op_params->{context}->{service_template} = $service_template;
    }

    $log->debug("New Operation Create with attrs : " . %params);
    Entity::Operation->enqueue(
        priority => 200,
        type     => 'AddCluster',
        params   => $op_params
    );
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
                my $instance = $self->addComponentFromType(component_type_id => $component->{component_type});
                if (defined $component->{component_configuration}) {
                    $instance->setConf(conf => $component->{component_configuration});
                }
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

    # Workaround to handle connectors that have btoh category.
    # We need to fix this when we willmerge inside/outside.
    my ($wok_disk_manager, $wok_export_manager);
    my $kanopya = Entity->get(id => Kanopya::Config::get("executor")->{cluster}->{executor});
    eval {
        $wok_disk_manager   = $args{managers}->{disk_manager}->{manager_id};
        $wok_export_manager = $args{managers}->{export_manager}->{manager_id};
    };
    if ($wok_disk_manager and $wok_export_manager) {
        # FileImagaemanager0 -> FileImagaemanager0
        if ($wok_disk_manager != $kanopya->getComponent(name => "Lvm", version => "2")->getAttr(name => 'component_id')) {
            $args{managers}->{export_manager}->{manager_id} = $wok_disk_manager;
        }
    }

    # Install new managers or/and new managers params if required
    if (defined $args{managers}) {
        # Add default workflow manager
        my $workflow_manager = $kanopya->getComponent(name => "Kanopyaworkflow", version => "0");
        $args{managers}->{workflow_manager} = {
            manager_id   => $workflow_manager->getId,
            manager_type => "workflow_manager"
        };

        # Add default collector manager
        my $collector_manager = $kanopya->getComponent(name => "Kanopyacollector", version => "1");
        $args{managers}->{collector_manager} = {
            manager_id   => $collector_manager->getId,
            manager_type => "collector_manager"
        };

        for my $manager (values %{$args{managers}}) {
            # Check if the manager is already set, add it otherwise,
            # and set manager parameters if defined.
            my $cluster_manager;
            eval {
                $cluster_manager = ServiceProviderManager->find(hash => { manager_type        => $manager->{manager_type},
                                                                          service_provider_id => $self->getId });
            };
            if ($@) {
                next if not $manager->{manager_id};
                $cluster_manager = $self->addManager(manager_id     => $manager->{manager_id},
                                                     manager_type   => $manager->{manager_type});

                if ($manager->{manager_type} eq 'collector_manager') {
                    $self->initCollectorManager(collector_manager => Entity->get(id => $manager->{manager_id}));
                }
            }

            if ($manager->{manager_params}) {
                $cluster_manager->addParams(params => $manager->{manager_params}, override => 1);
            }
        }
    }

    my $disk_manager   = $self->getManager(manager_type => 'disk_manager');
    my $export_manager = eval { $self->getManager(manager_type => 'export_manager') };

    # If the export manager exists, deduce the boot policy
    if ($export_manager) {
        my $bootpolicy = $disk_manager->getBootPolicyFromExportManager(export_manager => $export_manager);
        $self->setAttr(name => 'cluster_boot_policy', value => $bootpolicy);
        $self->save();
    }
    # Else use the boot policy to deduce the export manager to use
    else {
        $export_manager = $disk_manager->getExportManagerFromBootPolicy(
                              boot_policy => $self->getAttr(name => 'cluster_boot_policy')
                          );

        $self->addManager(manager_id => $export_manager->getId, manager_type => "export_manager");
    }

    # Get export manager parameter related to si shared value.
    my $readonly_param = $export_manager->getReadOnlyParameter(
                             readonly => $self->getAttr(name => 'cluster_si_shared')
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
    my $self = shift;
    my %args = @_;

    if (defined $args{interfaces}) {
        for my $interface_pattern (values %{ $args{interfaces} }) {
            if ($interface_pattern->{interface_role}) {
                my $role = Entity::InterfaceRole->get(id => $interface_pattern->{interface_role});

                # TODO: This mechanism do not allows to define many interfaces
                #       with the same role within policies.

                # Check if an interface with the same role already set, add it otherwise,
                # Add networks to the interrface if not exists.
                my $interface;
                eval {
                    $interface = Entity::Interface->find(
                                     hash => { service_provider_id => $self->getAttr(name => 'entity_id'),
                                               interface_role_id   => $role->getAttr(name => 'entity_id') }
                                 );
                };
                if ($@) {
                    my $default_gateway = (defined $interface_pattern->{default_gateway} && $interface_pattern->{default_gateway} == 1) ? 1 : 0;
                    $interface = $self->addNetworkInterface(interface_role  => $role,
                                                            default_gateway => $default_gateway);
                }

                if ($interface_pattern->{interface_networks}) {
                    for my $network_id (@{ $interface_pattern->{interface_networks} }) {
                        eval {
                            $interface->associateNetwork(network => Entity::Network->get(id => $network_id));
                        };
                        if($@) {
                            my $msg = 'Interface <' .$interface->id . '> already associated with network <' . $network_id . '>';
                            $log->debug($msg);
                        }
                    }
                }
            }
        }
    }
}

sub configureBillingLimits {
    my $self    = shift;
    my %args    = @_;

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
            my $wf_params   = $wf_def->getParamPreset();
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

=head2 remove

=cut

sub remove {
    my $self = shift;
    my $adm = Administrator->new();

    $log->debug("New Operation Remove Cluster with cluster id : " .  $self->getAttr(name => 'cluster_id'));
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

    $log->debug("New Operation Force Stop Cluster with cluster: " . $self->getAttr(name => "cluster_id"));
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

sub extension { return "clusterdetails"; }

sub activate {
    my $self = shift;

    $log->debug("New Operation ActivateCluster with cluster_id : " . $self->getAttr(name => 'cluster_id'));
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

    $log->debug("New Operation DeactivateCluster with cluster_id : " . $self->getAttr(name => 'cluster_id'));
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

    General::checkParams(args => \%args, required => [ 'category' ]);

    my $components_rs = $self->{_dbix}->parent->search_related("components", undef, {
                            '+columns' => {
                                "component_name"     => "component_type.component_name",
						        "component_version"  => "component_type.component_version",
						        "component_category" => "component_type.component_category",
                            },
	                        join => [ "component_type" ] }
	                    );

    my @components;
    while (my $component_row = $components_rs->next) {
        my $comp_id           = $component_row->get_column('component_id');
        my $comptype_category = $component_row->get_column('component_category');
        my $comptype_name     = $component_row->get_column('component_name');
        my $comptype_version  = $component_row->get_column('component_version');

        if ($args{category} eq "all" or $args{category} eq $comptype_category){
            my $class= "Entity::Component::" . $comptype_name . $comptype_version;
            my $loc = General::getLocFromClass(entityclass=>$class);
            eval { require $loc; };

            push @components, $class->get(id => $comp_id);
        }
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

sub getComponent{
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['name','version']);

    my $hash = {
        'component_type.component_name'    => $args{name},
        'component_type.component_version' => $args{version}
    };

    my $component_row;
    eval {
        my $components_rs = $self->{_dbix}->parent->search_related(
                                "components", $hash,
                                { "+columns" =>
                                    { "component_name"     => "component_type.component_name",
                                      "component_version"  => "component_type.component_version",
                                      "component_category" => "component_type.component_category" },
                                  join => [ "component_type" ] }
                            );

        $component_row = $components_rs->next;
    };
    if (not defined $component_row or $@) {
        throw Kanopya::Exception::Internal(
                  error => "Component with name <$args{name}>, version <$args{version}> " .
                           "not installed on this cluster:\n$@"
              );
    }

    my $comp_category = $component_row->get_column('component_category');
    my $comp_id       = $component_row->id;
    my $comp_name     = $component_row->get_column('component_name');
    my $comp_version  = $component_row->get_column('component_version');

    my $class= "Entity::Component::" . $comp_name . $comp_version;
    my $loc = General::getLocFromClass(entityclass => $class);

    eval { require $loc; };
    if ($@) {
        throw Kanopya::Exception::Internal::UnknownClass(error => "Could not find $loc :\n$@");
    }
    return "$class"->get(id => $comp_id);
}

sub getComponentByInstanceId{
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['component_instance_id']);

    my $hash = {'component_instance_id' => $args{component_instance_id}};
    my $comp_instance_rs = $self->{_dbix}->search_related("component_instances", $hash,
                                            { '+columns' => {"component_name" => "component.component_name",
                                                            "component_version" => "component.component_version",
                                                            "component_category" => "component.component_category"},
                                                    join => ["component"]});

    my $comp_instance_row = $comp_instance_rs->next;
    if (not defined $comp_instance_row) {
        throw Kanopya::Exception::Internal(error => "Component with component_instance_id '$args{component_instance_id}' not found on this cluster");
    }
    $log->debug("Comp name is " . $comp_instance_row->get_column('component_name'));
    $log->debug("Component instance found with " . ref($comp_instance_row));
    my $comp_category = $comp_instance_row->get_column('component_category');
    my $comp_instance_id = $comp_instance_row->get_column('component_instance_id');
    my $comp_name = $comp_instance_row->get_column('component_name');
    my $comp_version = $comp_instance_row->get_column('component_version');
    my $class= "Entity::Component::" . $comp_name . $comp_version;
    my $loc = General::getLocFromClass(entityclass=>$class);
    eval { require $loc; };
    return "$class"->get(id =>$comp_instance_id);
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
        return $master->getAdminIp;
    }

    return;
}

sub getMasterNodeFQDN {
    my $self = shift;

    return $self->getMasterNode()->host_hostname . '.' . $self->cluster_domainname;
}

sub getMasterNodeId {
    my $self = shift;
    my $host = $self->getMasterNode;

    if (defined ($host)) {
        return $host->getAttr(name => "host_id");
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

    my %hosts;
    eval {
        my @nodes = Externalnode::Node->search(hash => { inside_id => $self->getId });
        for my $node (@nodes) {
            my $host = $node->host;
            my $host_id = $host->getId;
            eval {
                $hosts{$host_id} = $host;
            };
        }
    };
    if ($@) {
        throw Kanopya::Exception::Internal(
                  error => "Could not get cluster nodes:\n$@"
              );
    }
    return \%hosts;
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

    $log->debug("New Operation StopCluster with cluster_id : " . $self->getAttr(name => 'cluster_id'));
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
    my $state = $self->{_dbix}->get_column('cluster_state');
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
    $self->{_dbix}->update({'cluster_prev_state' => $current_state,
                            'cluster_state' => $new_state.":".time})->discard_changes();;
}


sub getNewNodeNumber {
    my $self = shift;
    my $nodes = $self->getHosts();

    # if no nodes already registered, number is 1
    if(! keys %$nodes) { return 1; }

    my @current_nodes_number = ();
    while( my ($host_id, $host) = each(%$nodes) ) {
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

=head2 getNodeState


=cut

sub getNodeState {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['hostname']);

    my $host       = Entity::Host->find(hash => {host_hostname => $args{hostname}});
    my $host_id    = $host->getId();
    my $node       = Externalnode::Node->find(hash => {host_id => $host_id});
    my $node_state = $node->getAttr(name => 'node_state');

    return $node_state;
}

=head2 getNodesMetrics

    Desc: call collector manager to retrieve nodes metrics values.
    return \%data;

=cut

sub getNodesMetrics {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'time_span', 'indicators' ]);

    my $collector_manager   = $self->getManager(manager_type => "collector_manager");
    my $mparams             = $self->getManagerParameters( manager_type => 'collector_manager' );

    my $nodes = $self->getHosts();
    my @nodelist;

    while (my ($host_id, $host_object) = each(%$nodes)) {
        push @nodelist, $host_object->getAttr(name => 'host_hostname');
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
        Entity::NodemetricRule->new(%$prule);
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

1;
