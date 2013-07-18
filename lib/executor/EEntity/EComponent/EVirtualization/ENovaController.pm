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

package EEntity::EComponent::EVirtualization::ENovaController;

use base "EEntity::EComponent";
use base "EManager::EHostManager::EVirtualMachineManager";

use strict;
use warnings;

use JSON;
use General;
use OpenStack::API;
use NetAddr::IP;
use Data::Dumper;
use IO::Handle;
use File::Temp qw/ tempfile /;

use Log::Log4perl "get_logger";
my $log = get_logger("");

sub api {
    my $self = shift;

    my $credentials = {
        auth => {
            passwordCredentials => {
                username    => "admin",
                password    => "keystone"
            },
            tenantName      => "openstack"
        }
    };

    my $keystone = $self->keystone;
    my $config = {
        verify_ssl => 0,
        identity => {
            url     => 'http://' . $keystone->getMasterNode->fqdn . ':5000/v2.0'
        },
    };

    return OpenStack::API->new(credentials => $credentials,
                               config      => $config);
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
    
    General::checkParams(args => \%args, required => [ 'cluster', 'host' ]);

    eval {
        my $api = $self->api;
        my $route = 'os-security-groups';
        my $resp = $api->compute->$route->get();

        if (! scalar(@{$resp->{security_groups}})) {
            # We can't customize the default security group unless we create a
            # network or an other security group https://bugs.launchpad.net/quantum/+bug/1148538
            $resp = $api->compute->$route->post(
                content => {
                    security_group => {
                        name => 'foo',
                        description => 'removeme'
                    }
               }
            );

            if (defined ($resp->{security_group})) {
                $api->compute->$route(id => $resp->{security_group}->{id})->delete;
            }
        }

        my $group = $resp->{security_groups}->[0]->{id};
        $route = 'os-security-group-rules';
        $api->compute->$route->post(
            content => {
                security_group_rule => {
                    from_port       => 1,
                    to_port         => 65535,
                    ip_protocol     => "tcp",
                    cidr            => "0.0.0.0/0",
                    parent_group_id => $group,
                    group_id        => undef
                }
            }
        );

        $api->compute->$route->post(
            content => {
                security_group_rule => {
                    from_port       => 1,
                    to_port         => 65535,
                    ip_protocol     => "udp",
                    cidr            => "0.0.0.0/0",
                    parent_group_id => $group,
                    group_id        => undef
                }
            }
        );

        $api->compute->$route->post(
            content => {
                security_group_rule => {
                    from_port       => -1,
                    to_port         => -1,
                    ip_protocol     => "icmp",
                    cidr            => "0.0.0.0/0",
                    parent_group_id => $group,
                    group_id        => undef
                }
            }
        );
    };
}

sub registerHypervisor {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    return $self->addHypervisor(host => $args{host}->_entity);
}

sub unregisterHypervisor {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    return $self->removeHypervisor(host => $args{host}->_entity);
}

=pod

=begin classdoc

Migrate an openstack vm from one hypervisor to another

@params host the vm to migrate
@params hypervisor_dst the destination hypervisor

=end classdoc

=cut

sub migrateHost {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'hypervisor_dst' ]);

    my $host = $args{host};
    my $hv   = $args{hypervisor_dst};
    my $uuid = $host->openstack_vm_uuid;
    my $api  = $self->api;

    $log->info('migrating host <' . $host->id . '> on hypervisor < ' . $hv->id . '>');

    $api->compute->servers(id => $uuid)->action->post(
        content => {
            'os-migrateLive'  => {
                disk_over_commit => JSON::false,
                block_migration  => JSON::false,
                host             => $hv->node->node_hostname,
            }
        }
    );
}


=pod

=begin classdoc

Get all the vms of an hypervisor

@param host hypervisor

=end classdoc

=cut

sub getHypervisorVMs {
    my ($self, %args) = @_;

    if (! defined $args{host_id}) {
        General::checkParams(args => \%args, required => [ 'host' ]);
    }
    else {
        $args{host} = Entity::Host->get(id => $args{host_id});
        delete $args{host_id};
    }

    my $host = $args{host};

    my $route = 'os-hypervisors';
    my $hostname = $host->node->node_hostname;
    my $details = $self->api->compute->$route->$hostname
                       ->servers->get->{hypervisors};

    my @vms;
    my @vm_ids;
    my @unk_vm_uuids;

    my @uuids = (defined $details->[0]->{servers}) ? @{$details->[0]->{servers}} : ();

    for my $uuid (@uuids){
        eval {
            my $e = Entity::Host::VirtualMachine::OpenstackVm->find(hash => {openstack_vm_uuid => $uuid->{uuid}});
            push @vms, $e;
            push @vm_ids, $e->id;
        };
        if ($@) {
            my $error = $@;
            $log->info($uuid->{uuid}." => ".$error);
            push @unk_vm_uuids, $uuid->{uuid};
        }
    }

    return {
        vm_ids       => \@vm_ids,
        vms          => \@vms,
        unk_vm_uuids => \@unk_vm_uuids,
    };
}


=pod

=begin classdoc

Get the detail of a vm

@params host vm

=end classdoc

=cut

sub getVMDetails {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    my $host = $args{host};
    my $uuid = $host->openstack_vm_uuid;

    my $details =  $self->api->compute->servers(id => $uuid)->get;

    if (defined $details->{'itemNotFound'}) {
        throw Kanopya::Exception(error => "VM <".$args{host}->id."> not found in infrastructure");
    }

    return {
        state      => $details->{server}->{status},
        hypervisor => $details->{server}->{'OS-EXT-SRV-ATTR:host'},
    };
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

    eval {
        my $details =  $self->getVMDetails(%args);

        my $state_map = {
            'MIGRATING' => 'migr',
            'BUILD'     => 'pend',
            'REBUILD'   => 'pend',
            'ACTIVE'    => 'runn',
            'ERROR'     => 'fail',
            'SHUTOFF'   => 'shut'
        };
    
        return {
            state      => $state_map->{$details->{state}} || 'fail',
            hypervisor => $details->{hypervisor},
        };
    }
}

=pod

=begin clasddoc

Scale up or down the RAM of a given host

=end classdoc

=cut

sub scaleMemory {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'memory' ]);

    $self->_scaleHost(host => $args{host}, memory => $args{memory});
}

=pod

=begin classdoc

Scale up or down the number of CPU of a given host

=end classdoc

=cut

sub scaleCpu {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'cpu_number' ]);

    $self->_scaleHost(host => $args{host}, cpu_number => $args{cpu_number});
}

=pod

=begin classdoc

Terminate a host

=end classdoc

=cut

sub halt {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    my $uuid = $args{host}->openstack_vm_uuid;
    my $api = $self->api;

    $api->compute->servers(id => $uuid)->action->post(
        content => { 'os-stop' => undef }
    );
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

    if (! defined $args{hypervisor}) {
        throw Kanopya::Exception::Internal(error => "No hypervisor available");
    }

    my $api = $self->api;
    my $image_id;
    my $diskless = $args{cluster}->cluster_boot_policy ne Manager::HostManager->BOOT_POLICIES->{virtual_disk};

    if (not $diskless) {
        # Register system image
        $image_id = $self->registerSystemImage(host    => $args{host},
                                               cluster => $args{cluster});
    }
    else {
        $image_id = $self->registerPXEImage();
    }

    my $flavor = $api->compute->flavors(id => $args{cluster}->id)
                     ->get->{flavor};

    if ($flavor->{id}) {
        $api->compute->flavors(id => $flavor->{id})->delete;
    }

    $flavor = $api->compute->flavors->post(
        content => {
            flavor => {
                'name'                        => 'flavor_' . $args{host}->node->node_hostname,
                'ram'                         => $args{host}->host_ram / 1024 / 1024,
                'vcpus'                       => $args{host}->host_core,
                'id'                          => $args{cluster}->id,
                'swap'                        => 0,
                'os-flavor-access:is_public'  => JSON::true,
                'rxtx_factor'                 => 1,
                'OS-FLV-EXT-DATA:ephemeral'   => 0,
                'disk'                        => $diskless ?
                                                 0 : $args{host}->getNodeSystemimage
                                                                ->getContainer->container_size / 1024 / 1024
            },
        }
    );

    $log->debug("Nova returned " . (Dumper $flavor));

    my $interfaces;
    eval {
        # register network
        $interfaces = $self->registerNetwork(host => $args{host});
        my $ports;
        for my $interface (@$interfaces) {
            push @$ports, {
                port => $interface->{port}
            };
        }

        my $disk_manager = $args{cluster}->getManager(manager_type => 'DiskManager');
        my $isCinder     = 0;
        my $volume       = undef;
        my $apiRoute     = $api->compute->servers;
        if ($disk_manager->isa('Entity::Component::Openstack::Cinder')) {
            $isCinder    = 1;
            my $volumeId = $disk_manager->getVolumeId(container => $args{host}->getNodeSystemimage->getContainer);
            $volume      = [
                {
                    volume_size           => '',
                    volume_id             => $volumeId,
                    delete_on_termination => 0,
                    device_name           => 'vda'
                }
            ];
            my $route    = 'os-volumes_boot';
            $apiRoute    = $api->compute->$route;
        }

        # create VM
        my $response = $apiRoute->post(
            content => {
                server => {
                    availability_zone => 'nova:' . $args{hypervisor}->node->node_hostname,
                    flavorRef         => $flavor->{flavor}->{id},
                    name              => $args{host}->node->node_hostname,
                    networks          => $ports,
                    imageRef          => $image_id,
                    $isCinder ? ('block_device_mapping', $volume) : ()
                }
            }
        );

        $log->debug("Nova returned : " . (Dumper $response));

        $args{host} = Entity::Host::VirtualMachine::OpenstackVm->promote(
                          promoted           => $args{host}->_entity,
                          nova_controller_id => $self->id,
                          openstack_vm_uuid  => $response->{server}->{id},
                          hypervisor_id      => $args{hypervisor}->id
                      );

        $args{host}->hypervisor_id($args{hypervisor}->id);
    };
    if ($@) {
        my $error = $@;
        for my $interface (@$interfaces) {
            $self->deletePort(port => $interface->{port});
        }
        if (ref($error)) {
            $error->rethrow;
        }
        else {
            throw Kanopya::Exception::Execution(error => "$error");
        }
    }
}

=pod

=begin classdoc

Upload a system image to Glance

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

    my $econtext = $self->_host->getEContext;
    my $container_access = $image->getContainer->container_access;
    my $mount_point = EEntity->new(entity => $container_access)->mount(econtext => $econtext);

    my $image_source = $mount_point . '/' . $image->getContainer->container_device;
    my $image_container_format = 'bare'; # bare => no container or metadata envelope for the image
    my $image_is_public = 'True'; # accessible by all tenants

    my $response = $self->api->glance->images->post(
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

    EEntity->new(entity => $container_access)->umount(econtext => $econtext);

    return $response->{image}->{id};
}

=pod

=begin classdoc

Return the image to use for PXE boot.
If the PXE boot does not exist in Glance, register an empty one

@return $response->{image}->{id}  the id of the uploaded image

=end classdoc

=cut

sub registerPXEImage {
    my ($self, %args) = @_;

    my $images = $self->api->glance->images->get->{images};
    my ($pxe_image) = grep { $_->{name} eq "__PXE__" } @{$images};

    if (!$pxe_image) {
        my ($fh, $filename) = tempfile(UNLINK => 1);
        print $fh " " x 512;
        $fh->autoflush();

        my $response = $self->api->glance->images->post(
            headers         => {
                'x-image-meta-name'             => '__PXE__',
                'x-image-meta-disk_format'      => 'raw',
                'x-image-meta-container_format' => 'bare',
                'x-image-meta-is_public'        => 'True'
            },
            content         => $filename,
            content_type    => 'application/octet-stream'
        );

        $log->debug("Glance returned : " . (Dumper $response));
        $pxe_image = $response->{image};
    }

    return $pxe_image->{id};
}

=pod

=begin classdoc

Register a network to Quantum

@param $host host whose netconf to be registered

@returnlist list of created networks

=end classdoc

=cut

sub registerNetwork {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    my $host = $args{host};
    my $api = $self->api;

    my $interfaces = [];
    IFACE:
    for my $iface ($args{host}->getIfaces()) {
        # skip ifaces with no ip address
        eval{
            $iface->getIPAddr();
        };
        next IFACE if ($@);

        # get iface vlan
        my $vlan = undef;
        my @vlans = $iface->getVlans();
        if (scalar @vlans) {
            $vlan = pop @vlans;
        }

        my $network_conf = $self->_registerNetworkAndSubnet(
            vlan        => $vlan,
            iface       => $iface,
        );

        # create port to assign IP address
        my $port_id = $self->_registerPort(
            host        => $host,
            iface       => $iface,
            network_id  => $network_conf->{network_id},
            subnet_id   => $network_conf->{subnet_id}
        );

        push @$interfaces, {
            mac     => $iface->iface_mac_addr,
            network => $host->node->node_hostname . '-' . $iface->iface_name,
            port    => $port_id
        };
    }

    return $interfaces;
}

sub deletePort {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'port' ]);

    my $api = $self->api;
    my $port_id = $api->quantum->ports(id => $args{port})->delete();
}

sub stopHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    my $host = $args{host};
    my $api = $self->api;
    my $uuid = $host->openstack_vm_uuid;

    # get image id from openstack
    my $image_id = $api->compute->servers(id => $uuid)->get->{server}->{image}->{id};

    # delete image : set 'protected' attribute to false, then delete image
    $api->glance->images(id => $image_id)->put(
        headers => { 'x-image-meta-protected' => 'False' }
    );
    $api->glance->images(id => $image_id)->delete;

    # delete vm
    $api->compute->servers(id => $uuid)->delete;
}


sub releaseHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "host" ]);
    $args{host}->delete();
}


sub postStart {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);
}


=pod

=begin classdoc

Evacuate a vm in a hypervisor using nova 'evacuate' method.
Exception is thrown when hypervisor in not down for nova.

@param vm virtual machine to evacuate
@param hypervisor the hypervisor on which the vm is evacuated

=end classdoc

=cut

sub evacuateNode {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['vm', 'hypervisor']);

    $self->setState(vm => $args{vm}, state => 'active');

    my $api = $self->api;
    my $uuid = $args{vm}->openstack_vm_uuid;

    my $response = $api->compute->servers(id => $uuid)->action->post(
        content => {
            'evacuate' => {
                'host'            => $args{hypervisor}->node->node_hostname,
                'onSharedStorage' => 'true',
            }
        }
    );

    if (defined $response->{badRequest}) {
        throw Kanopya::Exception(error => 'Error from nova: '.$response->{badRequest}->{message});
    }
}

=pod

=begin classdoc

Resubmit a node in an OpenStack IAAS using evacuating method

@param vm virtual machine to resubmit
@param hypervisor hypervisor on which vm will be placed

return {need_to_scale => 0} indicating that nova does not need scale-in operation after resubmition

=end classdoc

=cut

sub resubmitNode {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['vm', 'hypervisor']);

    $self->evacuateNode(%args);

    return {need_to_scale => 0};
}

=pod

=begin classdoc

Get last message logged by a vm

@param $vm virtual machine whose logs are wanted

@return $lastmessage last message logged by vm

=end classdoc

=cut

sub vmLoggedErrorMessage {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'vm' ]);

    my $vm = $args{vm};
    my $instance_name = $self->_getInstanceName(vm => $vm);
    my $e_hypervisor = EEntity->new(entity => $vm->hypervisor);
    my $command = 'tail -n 10 /var/log/libvirt/qemu/'. $instance_name . '.log';

    $log->debug("command = $command");

    my $result  = $e_hypervisor->getEContext->execute(command => $command);
    my $output  = $result->{stdout};
    $log->debug($output);

    my @lastmessage = split '\n', $output;

    $log->debug(@lastmessage);

    return $lastmessage[-1];
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

Get name of an instance (vm) from nova compute's view

@param $vm virtual machine's name

@return $instance_name instance's name

=end classdoc

=cut

sub _getInstanceName {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'vm' ]);

    my $uuid = $args{vm}->openstack_vm_uuid;
    my $api = $self->api;

    my $instance_name = $api->compute->servers(id => $uuid)->get
                            ->{server}->{'OS-EXT-SRV-ATTR:instance_name'};

    return $instance_name;
}

sub _registerNetworkAndSubnet {
    my ($self, %args) = @_;

    General::checkParams(
        args => \%args,
        required => [ 'iface' ],
        optional => { vlan => undef }
    );

    my $api = $self->api;
    my $iface = $args{iface};
    my $poolip = $iface->getPoolip();
    my $network_addr = NetAddr::IP->new(
                           $poolip->network->network_addr,
                           $poolip->network->network_netmask
                       );
    my $network_id = undef;
    my $subnet_id = undef;

    my $subnets = $api->quantum->subnets->get;
    SUBNET:
    for my $subnet (@{ $subnets->{subnets} }) {
        if ( $subnet->{'cidr'} eq $network_addr->cidr ) {
            $subnet_id = $subnet->{id};
            # TODO comment + POD
            # check vlan correspondance
            my $network = $api->quantum->networks(id => $subnet->{network_id})->get;
            if ( ( (not exists $args{vlan}) and (not exists $network->{'provider:segmentation_id'}) ) or
                 ( (exists $args{vlan}) and ($network->{'provider:segmentation_id'} == $args{vlan}->vlan_number) )) {
                $network_id = $network->{id};
                last SUBNET;
            }

            # TODO : error management -> subnet overlaps, ... -- vlan with no ip
        }
    }

    if (not defined $network_id) {
        # TODO
            # new mapping
            # new network
    }

    return {
        network_id => $network_id,
        subnet_id  => $subnet_id
    };
}

sub _createNetworkMapping {
    # TODO : 1 mapping + update {compute,server}.pp + applyManifest
}

sub _registerPort {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'iface', 'network_id', 'subnet_id' ]);

    my $hostname    = $args{host}->node->node_hostname;
    my $iface       = $args{iface};
    my $network_id  = $args{network_id};
    my $subnet_id   = $args{subnet_id};
    my $api = $self->api;

    my $port_id = $api->quantum->ports->post(
        content => {
            'port' => {
                'name'          => $hostname . '-' . $iface->iface_name,
                'mac_address'   => $iface->iface_mac_addr,
                'fixed_ips'     => [
                    {
                        "ip_address"    => $iface->getIPAddr(),
                        "subnet_id"     => $subnet_id,
                    }
                ],
                'network_id'    => $network_id,
            }
        }
    )->{port}->{id};

    # TODO : log debug + err msg

    return $port_id;
}

=pod

=begin classdoc

Register a new flavor
@return the flavor id

=end classdoc

=cut

sub registerFlavor {
    my ($self, %args) = @_;

    General::checkParams(
        args => \%args,
        required => [ 'name', 'ram', 'vcpus', 'disk', 'id' ]
    );

    my $api = $self->api;
    my $id = $api->compute->flavors->post(
        content => {
            flavor => {
                'name'                        => $args{name},
                'ram'                         => $args{ram},
                'vcpus'                       => $args{vcpus},
                'disk'                        => $args{disk},
                'id'                          => $args{id},
                'swap'                        => 0,
                'os-flavor-access:is_public'  => JSON::true,
                'rxtx_factor'                 => 1,
                'OS-FLV-EXT-DATA:ephemeral'   => 0
            }
        }
    )->{flavor}->{id};
    return $id;
}


=pod

=begin classdoc

Generale scaling method (called by scaleCpu or scalememory)
Takes host and new memory / cpu count in parameter
Update host's flavor and resize host on the new flavor

=end classdoc

=cut

sub _scaleHost {
    my ($self, %args) = @_;

    General::checkParams(
        args     => \%args,
        required => [ 'host' ],
        optional => { memory => undef, cpu_number => undef }
    );

    throw Kanopya::Exception::NotImplemented(error => 'Scale in not supported by Openstack');

    my $api    = $self->api;
    my $node   = $args{host}->node;
    my $uuid   = $args{host}->openstack_vm_uuid;
    my $flavor = $api->compute->servers(id => $uuid)->get->{server}->{flavor};
    $flavor    = $api->compute->flavors(id => $flavor->{id})->get->{flavor};

    my $newFlavor_id = undef;
    if ($flavor->{id} eq $args{host}->id) {
        $api->compute->flavors(id => $flavor->{id})->delete;
        $newFlavor_id = $flavor->{id};
    }
    else {
        $newFlavor_id = $args{host}->id;
    }

    $newFlavor_id = $self->registerFlavor(
        id    => $newFlavor_id,
        name  => $node->node_hostname,
        ram   => (($args{memory} != undef) ? $args{memory} / 1024 / 1024 : $flavor->{ram}),
        vcpus => ($args{cpu_number} or $flavor->{vcpus}),
        disk  => $flavor->{disk}
    );

    # resize vm and confirm it
    $api->compute->servers(id => $uuid)->action->post(
        content => {
            resize  => {
                flavorRef   => $newFlavor_id
            }
        }
    );
    $api->compute->servers(id => $uuid)->action->post(
        content => {
            confirmResize => undef
        }
    );
}

=pod

=begin classdoc

Set nova vm state

@param host vm host
@param state force a particular state

=end classdoc

=cut

sub setState {
    my ($self, %args) = @_;

    General::checkParams(
        args     => \%args,
        required => [ 'vm', 'state' ],
    );

    my $api = $self->api;
    my $uuid = $args{vm}->openstack_vm_uuid;

    my $response = $api->compute->servers(id => $uuid)->action->post(
        content => {
            'os-resetState' => {
                'state'=> $args{state},
            }
        }
    );
}
1;
