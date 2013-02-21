#    Copyright © 2013 Hedera Technology SAS
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

=pod

=begin classdoc

EEntity for the OpenStack host manager

=end classdoc

=cut

package EEntity::EComponent::EOpenstack::ENovaController;

use base "EEntity::EComponent";
use base "EManager::EHostManager::EVirtualMachineManager";

use strict;
use warnings;

use JSON;
use OpenStack::API;

use Log::Log4perl "get_logger";
my $log = get_logger("");

sub api {
    my $self = shift;

    my $credentials = {
        auth => {
            passwordCredentials => {
                username    => "admin",
                password    => "pass"
            },
            tenantName      => "openstack"
        }
    };

    my $keystone = $self->keystone;
    my @glances  = $self->glances;
    my $glance   = shift @glances;
    my @computes = $self->novas_compute;
    my $compute  = shift @computes;
    my @quantums  = $self->quantums;
    my $quantum  = shift @quantums;

    my $config = {
        verify_ssl => 0,
        identity => {
            url     => 'http://' . $keystone->service_provider->getMasterNode->fqdn . ':5000/v2.0'
        },
        image => {
            url     => 'http://' . $glance->service_provider->getMasterNode->fqdn  . ':9292/v1'
        },
        compute => {
            url     => 'http://' . $compute->service_provider->getMasterNode->fqdn . ':8774/v2'
        },
        network => {
            url     => 'http://' . $quantum->service_provider->getMasterNode->fqdn . ':9696/v2.0'
        }
    };

    my $os_api = OpenStack::API->new(
        credentials => $credentials,
        config      => $config,
    );

    return $os_api;
}

sub addNode {
    my ($self, %args) = @_;

    General::checkParams(
        args     => \%args,
        required => [ 'host', 'mount_point', 'cluster' ]
    );
}

sub postStartNode {
    my ($self, %args) = @_;

    General::checkParams(
        args     => \%args,
        required => [ 'cluster', 'host' ]
    );
}

sub registerHypervisor {
    my ($self, %args) = @_;

    General::checkParams(
        args     => \%args,
        required => [ 'host' ]
    );
}

sub unregisterHypervisor {
    my ($self, %args) = @_;

    General::checkParams(
        args     => \%args,
        required => [ 'host' ]
    );
}

=pod

=begin classdoc

Migrate an host from one hypervisor to another

=end classdoc

=cut

sub migrateHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'host', 'hypervisor_dst', 'hypervisor_cluster' ]);
}

=pod

=begin classdoc

Retrieve the state of a given VM

@return state

=end classdoc

=cut

sub getVMState {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    my $host = $args{host};
    my $uuid = $host->openstack_vm_uuid;

    my $details =  $self->api->tenant(id => $self->api->{tenant_id})
                       ->servers(id => $uuid)
                       ->get(target => 'compute');

    return $details->{server}->{status};
}

=pod

=begin clasddoc

Scale up or down the RAM of a given host

=end classdoc

=cut

sub scaleMemory {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'memory' ]);
}

=pod

=begin classdoc

Scale up or down the number of CPU of a given host

=end classdoc

=cut

sub scaleCpu {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'cpu_number' ]);
}

=pod

=begin classdoc

Terminate a host

=end classdoc

=cut

sub halt {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);
}

=pod

=begin classdoc

Determine whether a host is up or down

=end classdoc

=cut

sub isUp {
    my ($self, %args) = @_;

    General::checkParams(
        args     => \%args,
        required => [ 'cluster', 'host' ]
    );

    return 1;
}

=pod

=begin classdoc

Start a new server on an OpenStack compute service, and register it into Kanopya

@return

=end classdoc

=cut

sub startHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host', 'cluster' ]);

    $args{hypervisor} = Entity::Host::Hypervisor::OpenstackHypervisor->find(hash => {});
    bless $args{hypervisor}, "Entity::Host::Hypervisor::OpenstackHypervisor";

    if (! defined $args{hypervisor}) {
        throw Kanopya::Exception::Internal(error => "No hypervisor available");
    }

    my $api = $self->api;
    my $image_id = $self->registerSystemImage(host    => $args{host},
                                              cluster => $args{cluster});

    my $image = $args{host}->getNodeSystemimage();
    my $flavor_id = $api->tenant(id => $api->{tenant_id})->flavors->post(
        target => 'compute',
        content => {
            flavor => {
                'name'                        => 'flavor_' . $args{host}->node->node_hostname,
                'ram'                         => $args{host}->host_ram / 1024 / 1024,
                'vcpus'                       => $args{host}->host_core,
                'disk'                        => $image->getContainer->container_size / 1024 / 1024,
                'id'                          => $args{cluster}->id,
                'swap'                        => 0,
                'os-flavor-access:is_public'  => JSON::true,
                'rxtx_factor'                 => 1,
                'OS-FLV-EXT-DATA:ephemeral'   => 0
            }
        }
    )->{flavor}->{id};

    my $response = $api->tenant(id => $api->{tenant_id})->servers->post(
        target => 'compute',
        content => {
            server => {
                flavorRef   => $flavor_id,
                imageRef    => $image_id,
                name        => $args{host}->node->node_hostname
            }
        }
    );

    $log->debug("Nova returned : " . (Dumper $response));

    $args{host} = Entity::Host::VirtualMachine::OpenstackVm->promote(
                      promoted           => $args{host}->_getEntity,
                      nova_controller_id => $self->id,
                      openstack_vm_uuid  => $response->{server}->{id},
                      hypervisor_id      => $args{hypervisor}->id
                  );
}

=pod

=begin classdoc

Upload an image to Glance

@return $response->{image}->{id}  the id of the uploaded image

=end classdoc

=cut

sub registerSystemImage {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'cluster' ]);

    my $image = $args{host}->getNodeSystemimage();
    my $disk_params = $args{cluster}->getManagerParameters(manager_type => 'DiskManager');
    my $image_name = $image->systemimage_name;
    my $image_type = $disk_params->{image_type};
    my $image_source = '/nfsexports/test_image_repository/' . $image->getContainer->container_device;
    my $image_container_format = 'bare'; # bare => no container or metadata envelope for the image
    my $image_is_public = 'True'; # accessible by all tenants

    my $response = $self->api->images->post(
        target          => 'image',
        headers         => {
            'x-image-meta-name'             => $image_name,
            'x-image-meta-disk_format'      => $image_type,
            'x-image-meta-container_format' => $image_container_format,
            'x-image-meta-is_public'        => $image_is_public
        },
        content         => $image_source,
        content_type    => 'application/octet-stream'
    );

    $log->debug("Glance returned : " . (Dumper $response));

    return $response->{image}->{id};
}

=pod

=begin classdoc

Register a network to Quantum

@return $response->{image}->{id}  the id of the created network

=end classdoc

=cut

sub registerNetwork {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    my $hostname = $args{host}->node->node_hostname;

    my $interfaces = [];
    for my $iface ($args{host}->getIfaces()) {
        my $vlan = undef;
        my @netconfs = $iface->netconfs;
        if (scalar @netconfs) {
            my $netconf = pop @netconfs;
            my @vlans = $netconf->vlans;
            if (scalar @vlans) {
                $vlan = pop @vlans;
            }
        }

        # create a network
        my $network_id = $self->api->networks->post(
            target  => 'network',
            content => {
                network => {
                    'name'                      => $hostname . '-network',
                    'admin_state_up'            => JSON::true
                }
            }
        )->{network}->{id};

        # create a subnet
        my $subnet_id = $self->api->subnets->post(
            target  => 'network',
            content => {
                subnet => {
                    'network_id'          => $network_id,
                    'ip_version'          => 4,
                }
            }
        )->{subnet}->{id};

        # create port to assign IP address
        my $port_id = $self->api->ports->post(
            target  => 'network',
            content => {
                port => {
                    'name'          => $hostname . '-' . $iface->iface_name,
                    'mac_address'   => $iface->iface_mac_addr,
                    "fixed_ips"     => [
                        {
                            "ip_address"    => $iface->getIPAddr,
                            "subnet_id"     => $subnet_id
                        }
                    ],
                    'network_id'  => $network_id,
                }
            }
        )->{port}->{id};

        push @$interfaces, {
            mac     => $iface->iface_mac_addr,
            network => $hostname . '-' . $iface->iface_name,
            port    => $port_id
        };
    }

    return $interfaces;
}

sub stopHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);
}

sub postStart {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);
}

sub applyVLAN {
    my ($self, %args) = @_;

    General::checkParams(
        args     => \%args,
        required => [ 'iface', 'vlan' ]
    );
}

=pod

=begin classdoc

Check the state of an OpenStack host

return boolean

=end classdoc

=cut

sub checkUp {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "host" ]);

    my $host = $args{host};
    my $vm_state = $self->getVMState(host => $host);

    $log->info('VM <' . $host->id . '> openstack status <' . $vm_state . '>');

    if ($vm_state eq 'SHUTOFF') {
    }

    return 0;
}

1;
