# Entity::ServiceProvider.pm

#    Copyright © 2011 Hedera Technology SAS
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
# Created 16 july 2010

=head1 NAME

Entity::ServiceProvider

=head1 SYNOPSIS

=head1 DESCRIPTION

blablabla

=cut

package Entity::ServiceProvider;
use base "Entity";

use General;
use Administrator;
use Kanopya::Exceptions;
use Entity::Component;
use Entity::Connector;
use Entity::Interface;

use ServiceProviderManager;

use List::Util qw[min max];
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    service_provider_name => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        addComponent => {
            description => 'add a component to this cluster',
            perm_holder => 'entity',
        },
        removeComponent => {
            description => 'remove a component from this cluster',
            perm_holder => 'entity',
        },
        addManager => {
            description => 'addManager',
            perm_holder => 'entity',
        },
        getNodeMonitoringData => {
            description => 'get monitoring data of a node',
            perm_holder => 'entity',
        },
        enableNode => {
            description => 'Enable node',
            perm_holder => 'entity',
        },
        disableNode => {
            description => 'Disable node',
            perm_holder => 'entity',
        },
        # TODO(methods): Remove this method from the api once the policy ui has been reviewed
        findManager => {
            description => 'findManager',
            perm_holder => 'mastergroup',
        },
        # TODO(methods): Remove this method from the api once the policy ui has been reviewed
        getServiceProviders => {
            description => 'getServiceProviders',
            perm_holder => 'mastergroup',
        },
        # TODO(methods): Remove this method from the api once the merge of component/connector
        addManagerParameters => {
            description => 'add paramaters to a manager',
            perm_holder => 'entity',
        },
        # TODO(methods): Remove this method from the api once the merge of component/connector
        getManagerParameters => {
            description => 'getManagerParameters',
            perm_holder => 'entity',
        },
    };
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
    return ExternalNode->get(id => $node_id)->getMonitoringData(%args);
}


=pod

=begin classdoc

Enable a node.

=end classdoc

=cut

sub enableNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'node_id' ]);

    return ExternalNode->get(id => $args{node_id})->enable();
}


=pod

=begin classdoc

Disable a node.

=end classdoc

=cut

sub disableNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'node_id' ]);

    return ExternalNode->get(id => $args{node_id})->disable();
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

    # The parent method getManager should disappeared
    if (defined $args{id}) {
        return Entity->get(id => $args{id});
    }

    General::checkParams(args => \%args, required => [ 'manager_type' ]);

    my $cluster_manager = ServiceProviderManager->find(hash => { manager_type        => $args{manager_type},
                                                                 service_provider_id => $self->getId }
                                                  );

    return Entity->get(id => $cluster_manager->getAttr(name => 'manager_id'));
}

sub getNodes {
    my ($self, %args) = @_;

    my @nodes = Externalnode->search(
                    hash => {
                        service_provider_id => $self->getId(),
                    }
    );

    my @node_hashs;

    for my $node (@nodes){

        my @verified_rules = VerifiedNoderule->search(
                                                   hash => {
                                                       verified_noderule_state => 'verified'
                                                   }
                                               );
        my @undef_rules    = VerifiedNoderule->search(
                                                   hash => {
                                                       verified_noderule_state => 'undef'
                                                   }
                                               );

        push @node_hashs, {
            state              => $node->getAttr(name => 'externalnode_state'),
            id                 => $node->getAttr(name => 'externalnode_id'),
            hostname           => $node->getAttr(name => 'externalnode_hostname'),
            num_verified_rules => scalar @verified_rules,
            num_undef_rules    => scalar @undef_rules,
        };
    }
    return \@node_hashs;
}

sub findManager {
    my $key;
    my ($class, %args) = @_;
    my @managers = ();

    if (defined $args{service_provider_id} and $args{service_provider_id} != 1 and $args{category} eq 'Export') {
        $args{category} = 'Storage';
    }

    $key = defined $args{id} ? { component_id => $args{id} } : {};
    $key->{service_provider_id} = $args{service_provider_id} if defined $args{service_provider_id};
    foreach my $component (Entity::Component->search(hash => $key)) {
        my $component_type = $component->component_type;
        if ($component_type->component_category eq $args{category}) {
            push @managers, {
                "category"            => $component_type->component_category,
                "name"                => $component_type->component_name,
                "id"                  => $component->id,
                "pk"                  => $component->id,
                "service_provider_id" => $component->service_provider_id,
                "host_type"           => $component->can("getHostType") ? $component->getHostType() : "",
            }
        }
    }

    $key = defined $args{id} ? { connector_id => $args{id} } : {};
    $key->{service_provider_id} = $args{service_provider_id} if defined $args{service_provider_id};
    foreach my $connector (Entity::Connector->search(hash => $key)) {
        my $connector_type = $connector->connector_type;

        if ($connector_type->connector_category eq $args{category}) {
            push @managers, {
                "category"            => $connector_type->connector_category,
                "name"                => $connector_type->connector_name,
                "id"                  => $connector->id,
                "pk"                  => $connector->id,
                "service_provider_id" => $connector->service_provider_id,
                "host_type"           => $connector->can("getHostType") ? $connector->getHostType() : "",
            }
        }
    }

    return wantarray ? @managers : \@managers;
}

sub getServiceProviders {
    my ($class, %args) = @_;
    my @providers;

    if (defined $args{category}) {
        my @managers = $class->findManager(category => $args{category});

        my $service_providers = {};
        for my $manager (@managers) {
            my $provider = Entity::ServiceProvider->get(id => $manager->{service_provider_id});
            if (not exists $service_providers->{$provider->getId}) {
                $service_providers->{$provider->getId} = $provider;
            }

            @service_providers = values %$service_providers;
        }
    }
    else {
        @service_providers = Entity::ServiceProvider->search(hash => {});
    }

    return wantarray ? @service_providers : \@service_providers;
}

=head2 addManager

    Desc: add a manager to a service provider
    Args: manager object (Component or connector entity) and $manager_type (string)
    Return: manager object

=cut


sub addManager {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'manager_id', "manager_type" ]);

    my $manager = ServiceProviderManager->new(
                      service_provider_id => $self->id,
                      manager_type        => $args{manager_type},
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

    my $cluster_manager = ServiceProviderManager->find(hash => { manager_type => $args{manager_type},
                                                         service_provider_id   => $self->getId });

    $cluster_manager->addParams(params => { $args{name} => $args{value} });
}


=pod

=begin classdoc

Set parameters of a manager defined by its type.

@param manager_type the of the manager on which we set the params
@param params the parameters hash to set 

=end classdoc

=cut

sub addManagerParameters {
    my $self = shift;

    General::checkParams(args     => \%args,
                         required => [ "manager_type", "params" ],
                         optional => { "override" => 0 });

    my $manager = ServiceProviderManager->find(hash => {
                      manager_type        => $args{manager_type},
                      service_provider_id => $self->id
                  });

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

    my $cluster_manager = ServiceProviderManager->find(hash => {
                              manager_type        => $args{manager_type},
                              service_provider_id => $self->getId
                          });

    return $cluster_manager->getParams();
}

=head2 addNetworkInterface

    Desc: add a network interface on this service provider

=cut

sub addNetworkInterface {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'interface_role' ]);

    my $params = {
        interface_role_id   => $args{interface_role}->getAttr(name => 'entity_id'),
        service_provider_id => $self->getAttr(name => 'entity_id')
    };
    if (defined $args{default_gateway}) {
        $params->{default_gateway} = $args{default_gateway};
    }
    my $interface = Entity::Interface->new(%$params);

    # Associate to networks if defined
    if (defined $args{networks}) {
        for my $network ($args{networks}) {
            $interface->associateNetwork(network => $network);
        }
    }
    return $interface;
}

=head2 getNetworkInterfaces

    Desc : return a list of NetworkInterface

=cut

sub getNetworkInterfaces {
    my ($self) = @_;

    # TODO: use the new BaseDb feature,
    # my @interfaces = $self->getRelated(name => 'interfaces');
    my @interfaces = Entity::Interface->search(
                         hash => { service_provider_id => $self->getAttr(name => 'entity_id') }
                     );

    return wantarray ? @interfaces : \@interfaces;
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
                $billing_limit_value = $billing_limit_value ? min($billing_limit_value, $limit->value) : $limit->value;
                $log->debug('Limit value'.($limit->value));
            }
        }

        # Get Limit from host_manager
        my $host_params = $self->getManagerParameters(manager_type => 'host_manager');

        my $host_limit_value;

        if ($args{type} eq 'ram') {
            if(defined $host_params->{max_ram}) {
                $host_limit_value = General::convertToBytes(
                                   value => $host_params->{max_ram},
                                   units => $host_params->{ram_unit}
                                );
            }
            else {
                $log->info('host limit ram undef');
            }
        }
        elsif ($args{type} eq 'cpu') {
            $host_limit_value = $host_params->{max_core};
        }

        $log->debug('sp <'.($self->getId).'> Type <'.($args{type}).'> Billing limit <'.($billing_limit_value).'> host limit <'.($host_limit_value).'>');

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

=head2 addComponent

    Desc: link a existing component with the cluster

=cut

sub addComponent {
    my ($self,%args) = @_;
    my $noconf;

    General::checkParams(args => \%args, required => ['component']);

    my $component = $args{component};
    $component->setAttr(name  => 'service_provider_id',
                        value => $self->id);
    $component->save();

    return $component;
}

=head2 addComponentFromType

    Desc: create a new componant and link it to the cluster

=cut

sub addComponentFromType {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'component_type_id' ]);

    my $comp_type = ComponentType->get(id => $args{component_type_id});

    # If the component is already installed, just return it
    my @components = Entity::Component->search(hash => { service_provider_id => $self->id,
                                                         component_type_id   => $args{component_type_id} });
    if (scalar @components) {
        return $components[0];
    }

    my $comp_class = $comp_type->component_class->class_type;
    my $location = General::getLocFromClass(entityclass => $comp_class);
    require $location;

    my $component = $comp_class->new();
    return $self->addComponent(component => $component);
}

1;
