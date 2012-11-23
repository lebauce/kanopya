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

package Entity::ServiceProvider;
use base "Entity";

use General;
use Administrator;
use Kanopya::Exceptions;
use Entity::Component;
use Entity::Connector;
use Entity::Interface;
use Externalnode;

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
        },
        removeComponent => {
            description => 'remove a component from this cluster',
        },
        addManager => {
            description => 'addManager',
        },
        getNodeMonitoringData => {
            description => 'get monitoring data of a node',
        },
        enableNode => {
            description => 'Enable node',
        },
        disableNode => {
            description => 'Disable node',
        },
        addManagerParameters => {
            description => 'add paramaters to a manager',
        },
        # TODO(methods): Remove this method from the api once the merge of component/connector
        getManagerParameters => {
            description => 'getManagerParameters',
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
    return Externalnode->get(id => $node_id)->getMonitoringData(%args);
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

    my @nodes = Externalnode->search(hash => {
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
            state              => $node->getAttr(name => 'externalnode_state'),
            id                 => $node->getAttr(name => 'externalnode_id'),
            hostname           => $node->getAttr(name => 'externalnode_hostname'),
            num_verified_rules => scalar @verified_rules,
            num_undef_rules    => scalar @undef_rules,
        };
    }
    return \@node_hashs;
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
    my %args = @_;

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

=head2 addConnector

link an existing connector with the outside service provider

=cut

sub addConnector {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['connector']);

    my $connector = $args{connector};
    $connector->setAttr(name  => 'service_provider_id',
                        value => $self->id);
    $connector->save();

    return $connector->id;
}

=head2 addConnectorFromType

Create and link a connector from type to the outside service provider

=cut

sub addConnectorFromType {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['connector_type_id']);

    my $type_id = $args{connector_type_id};
    my $adm = Administrator->new();
    my $row = $adm->{db}->resultset('ConnectorType')->find($type_id);
    my $conn_name = $row->get_column('connector_name');
    my $conn_class = 'Entity::Connector::'.$conn_name;
    my $location = General::getLocFromClass(entityclass => $conn_class);
    eval {require $location };
    my $connector = $conn_class->new();

    $self->addConnector( connector => $connector );

    return $connector->id;
}

sub removeConnector {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['connector_id']);

    my $connector = Entity::Connector->get(id => $args{connector_id});
    $connector->remove;

}

sub getConnectors {
    my $self = shift;
    my %args = @_;

    return Entity::Connector->search(
               hash => { service_provider_id => $self->id }
           );
}

1;
