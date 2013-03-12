#    Copyright © 2011 Hedera Technology SAS
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

TODO

=end classdoc

=cut

package Entity::ServiceProvider;
use base "Entity";

use General;
use ClassType::ComponentType;
use ClassType::ServiceProviderType;
use ComponentCategory::ManagerCategory;
use Entity::Component;
use Entity::Interface;

use ServiceProviderManager;

use List::Util qw[min max];
use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    service_provider_type_id => {
        pattern      => '^\d+$',
        is_mandatory => 0,
        is_extended  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        registerNode => {
            description => 'add a node to this service provider.',
        },
        addComponent => {
            description => 'add a component to this service provider.',
        },
        removeComponent => {
            description => 'remove a component from this service provider.',
        },
        addManager => {
            description => 'add a manager to this service provider.',
        },
        getNodeMonitoringData => {
            description => 'get monitoring data of a node.',
        },
        enableNode => {
            description => 'enable node.',
        },
        disableNode => {
            description => 'disable node',
        },
        addManagerParameters => {
            description => 'add paramaters to a manager.',
        },
        getManagerParameters => {
            description => 'get managers parameters.',
        },
    };
}


=pod

=begin classdoc

@constructor

Override the constructor to set the proper service provider type.

@return the service provider instance

=end classdoc

=cut

sub new {
    my $class = shift;
    my %args = @_;

    if ($class ne 'Entity::ServiceProvider') {
        (my $type = $class) =~ s/^.*:://g;
        $args{service_provider_type_id}
            = ClassType::ServiceProviderType->find(hash => { service_provider_name => $type })->id;
    }

    return $class->SUPER::new(%args);
}


=pod

=begin classdoc

Register a new node in the servie provider.
Also reconfigure the components about the node registration.

@return the registered node

=end classdoc

=cut

sub registerNode {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'hostname', 'number' ],
                         optional => { 'host'             => undef,
                                       'systemimage'      => undef,
                                       'state'            => undef,
                                       'monitoring_state' => 'enabled' });

    my $node = Node->new(
                   service_provider_id => $self->id,
                   node_hostname       => $args{hostname},
                   host_id             => $args{host} ? $args{host}->id : undef,
                   node_state          => $args{state} . ':' . time(),
                   monitoring_state    => $args{monitoring_state},
                   node_number         => $args{number},
                   systemimage_id      => $args{systemimage} ? $args{systemimage}->id : undef,
               );

    # Link the service provider components to the new node
    # TODO: Handle heterogeneous component configuration
    for my $component ($self->components) {
        $component->registerNode(node => $node, master_node => ($node->node_number == 1) ? 1 : 0);
    }
    return $node;
}

sub unregisterNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'node' ]);

    if (defined $args{node}->host) {
        # Free assigned ips
        my @ifaces = $args{node}->host->getIfaces;
        for my $iface (@ifaces) {
            my @ips = $iface->ips;
            for my $ip (@ips) {
                $ip->delete();
            }
        }
        $args{node}->host->setState(state => 'down');
    }
    $args{node}->remove();
}


=pod

=begin classdoc

Get the monitoring data for a node.

@return node monitoring data

=end classdoc

=cut

sub getNodeMonitoringData {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'node_id', 'indicator_ids' ]);

    my $node_id = delete $args{node_id};
    return Node->get(id => $node_id)->getMonitoringData(%args);
}


=pod

=begin classdoc

Enable a node.

=end classdoc

=cut

sub enableNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'node_id' ]);

    return Node->get(id => $args{node_id})->enable();
}


=pod

=begin classdoc

Disable a node.

=end classdoc

=cut

sub disableNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'node_id' ]);

    return Node->get(id => $args{node_id})->disable();
}

sub getNodesMetrics {}

sub getState {
    throw Kanopya::Exception::NotImplemented();
}

=head2 getManager

    Desc: get a service provider manager object
    Args: $manager_type (string)
    Return: manager object

=cut

sub getManager {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'manager_type' ]);

    my $cluster_manager = $self->findRelated(filters => [ 'service_provider_managers' ],
                                             custom  => { category => $args{manager_type} });

    return $cluster_manager->manager;
}

sub getNodes {
    my ($self, %args) = @_;

    my @nodes = Node->search(hash => {
                    service_provider_id => $self->getId(),
                });

    my @node_hashs;
    for my $node (@nodes){
        my @verified_rules = VerifiedNoderule->search(hash => {
                                verified_noderule_state => 'verified'
                             });
        my @undef_rules    = VerifiedNoderule->search(hash => {
                                verified_noderule_state => 'undef'
                             });

        push @node_hashs, {
            state              => $node->getAttr(name => 'monitoring_state'),
            id                 => $node->getAttr(name => 'node_id'),
            hostname           => $node->getAttr(name => 'node_hostname'),
            num_verified_rules => scalar @verified_rules,
            num_undef_rules    => scalar @undef_rules,
        };
    }
    return \@node_hashs;
}


=pod

=begin classdoc

Add a manager to a service provider

@param manager_id the id of the component to use as manager
@param manager_type the type of the manager to add

@return the ServiceProviderManager instance

=end classdoc

=cut

sub addManager {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'manager_id', 'manager_type' ]);

    my $category = ComponentCategory::ManagerCategory->find(hash => {
                       category_name => $args{manager_type}
                   });

    my $manager = ServiceProviderManager->new(
                      service_provider_id => $self->id,
                      manager_category_id => $category->id,
                      manager_id          => $args{manager_id}
                  );

    if ($args{manager_params}) {
        $manager->addParams(params => $args{manager_params});
    }
    return $manager;
}

=head2 addManagerParameter

    Desc: add  parameters to a service provider manager
    Args: manager type (string), param name (string) param value (string) (string)
    Return: none

=cut

sub addManagerParameter {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'manager_type', 'name', 'value' ]);

    my $cluster_manager = $self->findRelated(filters => [ 'service_provider_managers' ],
                                             custom  => { category => $args{manager_type} });

    $cluster_manager->addParams(params => { $args{name} => $args{value} });
}


=pod

=begin classdoc

Set parameters of a manager defined by its type.

@param manager_type the type of the manager on which we set the params
@param params the parameters hash to set 

=end classdoc

=cut

sub addManagerParameters {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "manager_type", "params" ],
                         optional => { "override" => 0 });

    my $manager = $self->findRelated(filters => [ 'service_provider_managers' ],
                                     custom  => { category => $args{manager_type} });

    $manager->addParams(params => $args{params}, override => $args{override});
}


=head2 getManagerParameters

    Desc: get a service provider manager parameters
    Args: manager type (string)
    Return: \%manager_params

=cut

sub getManagerParameters {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'manager_type' ]);

    my $cluster_manager = $self->findRelated(filters => [ 'service_provider_managers' ],
                                             custom  => { category => $args{manager_type} });

    return $cluster_manager->getParams();
}

=pod

=begin classdoc

Add a network interface on this service provider

=end classdoc

=cut

sub addNetworkInterface {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'netconfs' ],
                         optional => { 'bonds_number' => 0 });

    my $params = {
        service_provider_id => $self->id,
        bonds_number        => $args{bonds_number},
        netconf_interfaces  => $args{netconfs},
    };
    return Entity::Interface->new(%$params);
}

=head2 removeNetworkInterface

    Desc: remove a network interface

=cut

sub removeNetworkInterface {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['interface_id']);

    Entity::Interface->get(id => $args{interface_id})->delete();
}

sub getLimit {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "type" ]);

    #If there is a billing limit, use it, otherwise return undef
    eval {
        # Firtly get billing limit
        #
        # TODO: Use only one request
        my @limits = Entity::Billinglimit->search(hash => {
                         service_provider_id => $self->getId,
                         soft                => 0,
                         type                => $args{type},
                     });
    };
    if (scalar (@limits) != 0) {
        my $billing_limit_value;
        my $now = time() * 1000;
        for my $limit (@limits) {
            if (($limit->start < $now) && ($limit->ending > $now)){ 
                $billing_limit_value = $billing_limit_value ?
                                           min($billing_limit_value, $limit->value) : $limit->value;
            }
        }

        # Get Limit from host_manager
        my $host_params = $self->getManagerParameters(manager_type => 'HostManager');

        my $host_limit_value;

        if ($args{type} eq 'ram') {
            if(defined $host_params->{max_ram}) {
                $host_limit_value = $host_params->{max_ram};
            }
            else {
                $log->info('host limit ram undef');
            }
        }
        elsif ($args{type} eq 'cpu') {
            $host_limit_value = $host_params->{max_core};
        }

        my $value;
        if (defined $billing_limit_value){
            if ( defined $host_limit_value ) {
                $value = min( $billing_limit_value, $host_limit_value  );
            }
            else {
                $value = $billing_limit_value;
            }
        }
        else {
            $value = $host_limit_value;
        }
        return $value;
    }
    else {
        return;
    } 
}


=pod

=begin classdoc

Create a new componant and link it to the cluster

@param component_type_id ID of the component to be added
@param default_configuration the defaut configuration to be setted to component

@return component

=end classdoc

=cut

sub addComponent {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'component_type_id' ],
                         optional => { 'component_configuration' => undef,
                                       'component_template_id'   => undef });

    # Check if the type of the given component is installable on this type
    # of service provider.
    my $component_type = ClassType::ComponentType->get(id => $args{component_type_id});

    # For instance, allow the addiction of component on generic service providers
    if (defined $self->service_provider_type) {
        my @service_provider_types = $component_type->service_provider_types;
        if (scalar (grep { $_->id == $self->service_provider_type_id } @service_provider_types) <= 0) {
            throw Kanopya::Exception::Internal(
                      error => "Component type <" . $component_type->component_name .
                               "> can not be installed on a service provider of type <" .
                               $self->service_provider_type->service_provider_name . ">."
                  );
        }
    }

    # If the component is already installed, just return it
    my $installed;
    eval {
        $installed = $self->findRelated(filters => [ 'components' ],
                                        hash    => { component_type_id   => $args{component_type_id} });
    };
    if (not $@) {
        return $installed;
    }

    my $comp_class = $component_type->class_type;
    my $location = General::getLocFromClass(entityclass => $comp_class);
    require $location;

    # set component's configuration or use default
    my $component;
    if (defined $args{component_configuration}) {
        $component = $comp_class->new(service_provider_id   => $self->id,
                                      component_template_id => $args{component_template_id},
                                      %{ $args{component_configuration} });
    }
    else {
        $component = $comp_class->new(service_provider_id   => $self->id,
                                      component_template_id => $args{component_template_id});
    }

    # For instance install the component on all node of the service provider,
    # use the first started node as master node for the component.
    for my $node ($self->nodes) {
        $component->registerNode(node => $node, master_node => ($node->node_number == 1));
    }

    # Insert default configuration for tables linked to component (when exists)
    $component->insertDefaultExtendedConfiguration();

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

    my $findargs = {
        hash => { 'service_provider_id' => $self->id }
    };

    if (defined ($args{category}) and $args{category} ne "all") {
        $findargs->{custom}->{category} = $args{category};
    };

    my @components = Entity::Component->search(%$findargs);

    if (defined ($args{order_by})) {
        my $criteria = $args{order_by};
        @components = sort { $a->$criteria <=> $b->$criteria } @components;
    }

    return wantarray ? @components : \@components;
}

sub getComponent {
    my ($self, %args) = @_;

    General::checkParams(args => \%args);

    my $findargs = {
        hash => { 'service_provider_id' => $self->id }
    };

    if (defined ($args{name})) {
        $findargs->{hash}->{'component_type.component_name'} = $args{name};
    }

    if (defined ($args{category})) {
        $findargs->{custom}->{category} = $args{category};
    }

    if (defined ($args{version})) {
        $findargs->{hash}->{'component_type.component_version'} = $args{version};
    }

    return Entity::Component->find(%$findargs);
}

1;
