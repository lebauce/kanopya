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

use Kanopya::Exceptions;
use General;
use Entity::Component;
use Entity::Connector;
use Entity::Interface;
use Administrator;
use ServiceProviderManager;
use Entity::Component::Fileimagemanager0;
use Entity::Connector::NetappVolumeManager;
use Entity::Connector::NetappLunManager;

use List::Util qw[min max];
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        'findManager'   => {
            'description'   => 'findManager',
            'perm_holder'   => 'entity'
        },
        'getManager'    => {
            'description'   => 'getManager',
            'perm_holder'   => 'entity'
        },
        'getServiceProviders' => {
            'description'   => 'getServiceProviders',
            'perm_holder'   => 'entity'
        },
        'addManager'    => {
            'description'   => 'addManager',
            'perm_holder'   => 'entity'
        }
    };
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

sub getState {
    throw Kanopya::Exception::NotImplemented();
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
        my $obj = $component->getComponentAttr();
        if ($obj->{component_category} eq $args{category}) {
            push @managers, {
                "category"            => $obj->{component_category},
                "name"                => $obj->{component_name},
                "id"                  => $component->getAttr(name => "component_id"),
                "pk"                  => $component->getAttr(name => "component_id"),
                "service_provider_id" => $component->getAttr(name => "service_provider_id"),
                "host_type"           => $component->can("getHostType") ? $component->getHostType() : "",
            }
        }
    }

    $key = defined $args{id} ? { connector_id => $args{id} } : {};
    $key->{service_provider_id} = $args{service_provider_id} if defined $args{service_provider_id};
    foreach my $connector (Entity::Connector->search(hash => $key)) {
        my $obj = $connector->getConnectorType();

        if ($obj->{connector_category} eq $args{category}) {
            push @managers, {
                "category"            => $obj->{connector_category},
                "name"                => $obj->{connector_name},
                "id"                  => $connector->getAttr(name => "connector_id"),
                "pk"                  => $connector->getAttr(name => "connector_id"),
                "service_provider_id" => $connector->getAttr(name => "service_provider_id"),
                "host_type"           => $connector->can("getHostType") ? $connector->getHostType() : "",
            }
        }
    }

    # Workaround to get the Fileimagemanager0 in the disk manager list of an external equipment.
    # We really need to fix this.
#    if (defined $args{service_provider_id} and $args{service_provider_id} != 1) {
#        if ($args{category} eq 'Storage') {
#            eval {
#                $fileimagemanager = Entity::Component::Fileimagemanager0->find(hash => { service_provider_id => 1 });
#                push @managers, {
#                     "category"            => 'Storage',
#                     "name"                => 'Fileimagemanager',
#                     "id"                  => $fileimagemanager->getAttr(name => "component_id"),
#                     "pk"                  => $fileimagemanager->getAttr(name => "component_id"),
#                     "service_provider_id" => $fileimagemanager->getAttr(name => "service_provider_id"),
#                     "host_type"           => $fileimagemanager->can("getHostType") ? $fileimagemanager->getHostType() : "",
#                };
#            };
#        }
#    }

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
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'manager_id', "manager_type" ]);

    my $manager = ServiceProviderManager->new(
                      service_provider_id   => $self->getAttr(name => 'entity_id'),
                      manager_type => $args{manager_type},
                      manager_id   => $args{manager_id}
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

    # TODO: Use only one request
    my @limits = Entity::Billinglimit->search(hash => {
                     service_provider_id => $self->getId,
                     soft                => 0,
                     type                => $args{type},
                 });

    my $value;
    my $now = time();
    for my $limit (@limits) {
        if (($limit->start < $now) && ($limit->ending > $now)) {
            $value = $value ? min($value, $limit->value) : $limit->value;
        }
    }

    return $value;
}

1;
