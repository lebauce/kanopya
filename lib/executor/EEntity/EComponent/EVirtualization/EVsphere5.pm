#    Copyright © 2011-2012 Hedera Technology SAS
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

EVsphere

=end classdoc

=cut

package EEntity::EComponent::EVirtualization::EVsphere5;

use base "EEntity::EComponent::EVirtualization";
use base "EManager::EHostManager::EVirtualMachineManager";

use strict;
use warnings;

use Entity::Component::Vsphere5::Vsphere5Datacenter;
use Entity::Repository;
use Entity::Repository::Vsphere5Repository;
use Entity;
use Entity::Host::Hypervisor;
use Entity::ContainerAccess;
use Entity::Host::VirtualMachine::Vsphere5Vm;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;

my $log = get_logger("executor");
my $errmsg;

=pod

=begin classdoc

Register a new datastore for an host in vSphere or check existing one

@param container_access the Kanopya container access
@param repository_name the name of the datastore
@param host_view view of hypervisor

@return repository

=end classdoc

=cut

sub addDatastore {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['container_access', 'repository_name', 'host_view']);

    $self->negociateConnection();

    my $container_access    = $args{container_access};
    my $host_view           = $args{host_view};
    my $container_access_ip = $container_access->container_access_ip;
    my $export_full_path    = $container_access->container_access_export;
    my @export_path         = split (':', $export_full_path);

    my $nas_vol_spec = HostNasVolumeSpec->new(accessMode => 'readWrite',
            remoteHost => $container_access_ip,
            localPath  => $args{repository_name},
            remotePath => $export_path[1],
       );

    my $host_ds_sys = $self->getView(mo_ref => $host_view->configManager->datastoreSystem);
    eval {
        $host_ds_sys->CreateNasDatastore(spec => $nas_vol_spec);
    };
    if ($@) {
        $log->debug('Use existing datastore ' . $args{repository_name});
    }
}

=pod

=begin classdoc

Create and start a vphere vm

@param hypervisor the hypervisor that will host the vm
@param host the kanopya VirtualMachine object created to hold the vm

=end classdoc

=cut

sub startHost {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['hypervisor', 'host']);

    $log->info('Calling startHost on EVSphere '. ref($self));

    $self->negociateConnection();

    my $host       = $args{host};
    my $hypervisor = $args{hypervisor};
    # TODO depending on systemimage ?
    my $guest_id   = 'debian6_64Guest';

    $log->info('Start host on < hypervisor '. $hypervisor->id.' >');

    if (!defined $hypervisor) {
        my $errmsg = "Cannot add node in cluster ".$host->getClusterId().", no hypervisor available";
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    my $cluster     = Entity->get(id => $host->getClusterId());
    my $disk_params = $cluster->getManagerParameters(manager_type => 'DiskManager');
    my $host_params = $cluster->getManagerParameters(manager_type => 'HostManager');
    my $datacenter  = Entity::Component::Vsphere5::Vsphere5Datacenter->find(hash => {
                          vsphere5_datacenter_id => $hypervisor->vsphere5_datacenter_id
                      });

    my $container_access = Entity::ContainerAccess->get(id => $disk_params->{container_access_id});

    #retrieve datacenter view
    my $datacenter_view = $self->findEntityView(view_type   => 'Datacenter',
                                             hash_filter => {
                                                 name => $datacenter->vsphere5_datacenter_name
                                             });

    #retrieve host view
    my $host_view = $self->findEntityView(view_type   => 'HostSystem',
                     hash_filter => {
                         'hardware.systemInfo.uuid' => $hypervisor->vsphere5_uuid
                     },
                     begin_entity => $datacenter_view,
                 );

    # register repo in kanopya
    my $repository = $self->addRepository(container_access => $container_access);
    # register repo in VSphere
    $self->addDatastore(
        container_access => $container_access,
        repository_name  => $repository->repository_name,
        host_view        => $host_view,
    );

    my @ifaces = $args{host}->getIfaces();
    my %host_conf = (
        hostname   => $host->node->node_hostname,
        guest_id   => $guest_id,
        datastore  => $repository->repository_name,
        img_name   => $host->getNodeSystemimage()->systemimage_name,
        image_type => $disk_params->{image_type},
        img_size   => $host->getNodeSystemimage->getContainer->container_size,
        memory     => $host_params->{ram},
        cores      => $host_params->{core},
        network    => 'VM Network',
    );

    $log->debug('new VM configuration parameters: ');
    $log->debug(Dumper \%host_conf);
    $host_conf{ifaces} = \@ifaces;
    $log->debug('Ifaces => ' . scalar @ifaces);

    #Create vm in vsphere
    my $vm_view = $self->createVm(
                      host_conf       => \%host_conf,
                      host_view       => $host_view,
                      datacenter_view => $datacenter_view,
                  );

    #Power On
    eval {
        $vm_view->PowerOnVM();
    };
    if ($@) {
        my $errmsg = 'Error while powering on VM ' . $host->id . ' : ' . $@;
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    #Declare the vsphere5 vm in Kanopya
    $self->promoteVm(
        host          => $host->_entity,
        vm_uuid       => $vm_view->config->uuid,
        hypervisor_id => $hypervisor->id,
        guest_id      => $guest_id,
    );
}

=pod

=begin classdoc

Create a new VM on a vSphere host

@param host_conf the new vm configuration

=end classdoc

=cut

sub createVm {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host_conf', 'datacenter_view', 'host_view']);

    my %host_conf = %{$args{host_conf}};
    my $ds_path   = '['.$host_conf{datastore}.']';
    my $path      = $ds_path . ' ' . $host_conf{img_name} . '.' . $host_conf{image_type};
    my $host_view = $args{host_view};
    my $datacenter_view = $args{datacenter_view};
    my $vm_folder_view;
    my $comp_res_view;
    my @vm_devices;

    #Generate vm's devices specifications
    my @controller_conf_spec = $self->create_conf_spec();
    push @vm_devices, @controller_conf_spec;

    my $disk_conf_spec = $self->create_virtual_disk(
                                    path => $path,
                                    disksize => $host_conf{img_size}
                                );
    push(@vm_devices, $disk_conf_spec);

    my @net_settings = $self->get_network(
                           network_name => $host_conf{network},
                           ifaces       => $host_conf{ifaces},
                           host_view    => $host_view,
                           dc_view      => $datacenter_view,
                       );
    push(@vm_devices, @net_settings);

    my $files = VirtualMachineFileInfo->new(
                    logDirectory      => undef,
                    snapshotDirectory => undef,
                    suspendDirectory  => undef,
                    vmPathName        => $ds_path
                );

    my $vm_config_spec = VirtualMachineConfigSpec->new(
                             name         => $host_conf{hostname},
                             memoryMB     => $host_conf{memory} / 1024 / 1024,
                             files        => $files,
                             numCPUs      => $host_conf{cores},
                             guestId      => $host_conf{guest_id},
                             cpuHotAddEnabled => 1,
                             memoryHotAddEnabled => 1,
                             deviceChange => \@vm_devices
                         );

    #retrieve the vm folder from vsphere inventory
    $vm_folder_view = $self->getView(mo_ref => $datacenter_view->vmFolder);

    #retrieve the host parent view
    $comp_res_view  = $self->getView(mo_ref => $host_view->parent);

    #finally create the VM
    my $vm_mor;
    eval {
        # TODO task status for error management
        $vm_mor = $vm_folder_view->CreateVM(
            config => $vm_config_spec,
            pool   => $comp_res_view->resourcePool,
            host   => $host_view,
        );
    };
    if ($@) {
        $errmsg = 'Error while creating the virtual machine on host '.$host_conf{hypervisor}.': '.$@;
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    my $vm_view = $self->getView(mo_ref => $vm_mor);
    return $vm_view;
}

=pod

=begin classdoc

Scale In CPU for a vsphere vm. Throws an exception if the given host is not a Vsphere5vm
Get the vm's hypervisor, get it's datacenter, then retrieve views

@param host the vm
@param cpu_number the new amount of desired cpu

=end classdoc

=cut

sub scaleCpu {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'cpu_number' ]);

    my $host       = $args{host};
    my $cpu_number = $args{cpu_number};

    #determine the nature of the host and reject non vsphere ones
    if (ref $host eq 'EEntity::EHost::EVirtualMachine::EVsphere5Vm') {
        my $hypervisor = $host->hypervisor;
        my $dc_name    = $hypervisor->vsphere5_datacenter->vsphere5_datacenter_name;

        #get datacenter's view
        my $dc_view = $self->findEntityView(
                          view_type   => 'Datacenter',
                          hash_filter => {
                              name => $dc_name,
                          },
                      );

        #get the vm's view
        my $vm_view = $self->findEntityView(
                          view_type    => 'VirtualMachine',
                          hash_filter  => {
                              name => $host->node->node_hostname,
                          },
                          begin_entity => $dc_view,
                      );

        #Now we do the VM Scale In through ReconfigVM() method
        my $new_vm_config_spec = VirtualMachineConfigSpec->new(
                                     numCPUs => $cpu_number,
                                 );
        eval {
                $vm_view->ReconfigVM(
                    spec => $new_vm_config_spec,
                );
        };
        if ($@) {
            $errmsg = 'Error scaling in CPU on virtual machine '.$host->node->node_hostname.': '.$@;
            throw Kanopya::Exception::Internal(error => $errmsg);
        }
        #We Refresh the values of view
        #with corresponding server-side object values
        $vm_view->update_view_data;
    }
    else {
        $errmsg = 'The host type: ' . ref $host . ' is not handled by this manager';
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}

=pod

=begin classdoc

Scale In memory for a vsphere vm. Throws an exception if the given host is not a Vsphere5vm
Get the vm's hypervisor, get it's datacenter, then retrieve views

@param host the vm
@param memory the new amount of desired memory

=end classdoc

=cut

sub scaleMemory {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['host', 'memory']);

    my $host   = $args{host};
    my $memory = $args{memory};

    #determine the nature of the host and reject non vsphere ones
    if (ref $host eq 'EEntity::EHost::EVirtualMachine::EVsphere5Vm') {
        my $hypervisor = $host->hypervisor;
        my $dc_name    = $hypervisor->vsphere5_datacenter->vsphere5_datacenter_name;

        #get datacenter's view
        my $dc_view = $self->findEntityView(
                          view_type   => 'Datacenter',
                          hash_filter => {
                              name => $dc_name,
                          },
                      );

        #get the vm's view
        my $vm_view = $self->findEntityView(
                          view_type    => 'VirtualMachine',
                          hash_filter  => {
                              name => $host->node->node_hostname,
                          },
                          begin_entity => $dc_view,
                      );

        #Now we do the VM Scale In through ReconfigVM() method
        my $vm_new_config_spec = VirtualMachineConfigSpec->new(
                                     memoryMB => $memory  / 1024 / 1024,
                                 );

        eval {
            $vm_view->ReconfigVM(
                spec => $vm_new_config_spec,
            );
        };
        if ($@) {
            $errmsg = 'Error scaling in Memory on virtual machine '.$host->node->node_hostname.': '.$@;
            throw Kanopya::Exception::Internal(error => $errmsg);
        }
        #We Refresh the values of view
        #with corresponding server-side object values
        $vm_view->update_view_data;
    }
    else {
        $errmsg = 'The host type: ' . ref $host . ' is not handled by this manager';
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}

sub create_conf_spec {
    my ($self, %args) = @_;

    my ($controller_ide_spec, $controller_pci_spec);

    eval {
        $controller_ide_spec = VirtualDeviceConfigSpec->new(
            device => VirtualIDEController->new(key => 200, busNumber => 0),
            operation => VirtualDeviceConfigSpecOperation->new('add'),
        );

        $controller_pci_spec = VirtualDeviceConfigSpec->new(
            device => VirtualPCIController->new(key => 100, busNumber => 0),
            operation => VirtualDeviceConfigSpecOperation->new('add'),
        );
    };
    if ($@) {
        $errmsg = 'Error creating the virtual machine controller configuration: '.$@;
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    return ($controller_ide_spec, $controller_pci_spec);
}

sub create_virtual_disk {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'path', 'disksize']);

    my $disk_vm_dev_conf_spec;
    my $disk_backing_info;
    my $disk;

    eval {
        $disk_backing_info = VirtualDiskFlatVer2BackingInfo->new(
            diskMode => 'persistent',
            fileName => $args{path}
        );

        $disk = VirtualDisk->new(
            backing       => $disk_backing_info,
            controllerKey => 200,
            key           => 1,
            unitNumber    => 0,
            capacityInKB  => $args{disksize} / 1024
        );

        $disk_vm_dev_conf_spec = VirtualDeviceConfigSpec->new(
            device        => $disk,
            operation     => VirtualDeviceConfigSpecOperation->new('add')
        );
    };
    if ($@) {
        $errmsg = 'Error creating the virtual machine disk configuration: '.$@;
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    return $disk_vm_dev_conf_spec;
}

sub get_network {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'network_name', 'host_view', 'dc_view' ]);

    my $network_name = $args{network_name};
    my $host_view    = $args{host_view};
    my $datacenter_view    = $args{dc_view};
    my $key          = 2;
    my $unit_num     = 1;
    my ($network_list, $network, $vlan, @vlans, $nic_backing_info, $vd_connect_info, $nic,
    $nic_conf_spec, $desc);

    my @network_conf = ();
    eval {
        $network_list = $self->getViews(mo_ref_array => $host_view->network);
        ($network) = grep { $_->name eq $network_name } @{$network_list};

        if ($network) {
            my $ipPoolManager = $self->getView(
                mo_ref => $datacenter_view->{vim}->{service_content}->{ipPoolManager}
            );
            IFACE:
            for my $iface (@{ $args{ifaces} }) {
                # skip ifaces without ip address
                eval {
                    $iface->getIPAddr();
                };
                next IFACE if ($@);

                # TODO : register vlan on port group || synchronize NetConfs
                $vlan = undef;
                @vlans = $iface->getVlans();
                if (scalar @vlans) {
                    $vlan = pop @vlans;
                }

                my $poolip = $iface->getPoolip();

                # create PoolIP and register  it to datacenter + associate network
                my $ipv4Config = IpPoolIpPoolConfigInfo->new(
                    ipPoolEnabled => 1,
                    dns           => [
                        $iface->host->getCluster->cluster_nameserver1,
                        $iface->host->getCluster->cluster_nameserver2,
                    ],
                    gateway       => $poolip->network->network_gateway,
                    range         => $poolip->poolip_first_addr . ' # ' . $poolip->poolip_size,
                    netmask       => $poolip->network->network_netmask,
                    subnetAddress => $poolip->network->network_addr,
                    dhcpServerAvailable => 1,
                );
                my $networkAssociation = IpPoolAssociation->new(
                    networkName => $network->name,
                    network     => $network,
                );
                my $poolipSpec = IpPool->new(
                    name       => $poolip->poolip_name,
                    dnsDomain  => $iface->host->getCluster->cluster_domainname,
                    ipv4Config => $ipv4Config,
                    networkAssociation => [ $networkAssociation ],
                );

                eval {
                    # TODO Synchronized IP Pools in stead of registering for each iface
                    $ipPoolManager->CreateIpPool(dc => $datacenter_view, pool => $poolipSpec);
                };
                if ($@) {
                    $log->debug('Pool ip ' . $poolip->poolip_name . ' already registered on datacenter '
                        . $datacenter_view->name);
                }

                $nic_backing_info = VirtualEthernetCardNetworkBackingInfo->new(
                    deviceName => $network_name, # network to which interface will be connected
                        # TODO : portGroup/Vlan on an hypervisor + same name on all hypervisors of datacenter
                    network    => $network
                );

                $vd_connect_info = VirtualDeviceConnectInfo->new(
                    allowGuestControl => 1,
                    connected         => 1,
                    startConnected    => 1,
                );

                $desc = Description->new(
                    label => $iface->host->node->node_hostname . '-' . $iface->iface_name,
                    summary => 'Vitual Ethernet card ' . $iface->iface_name . ' for host '
                                   . $iface->host->node->node_hostname,
                );

                #TODO: mac address pattern must be given as a host manager param
                # for use in generateMacAddress method
                (my $mac_address = $iface->iface_mac_addr) =~ s/^([a-f0-9]{2}:){4}/00:50:56:3f:/;
                $iface->iface_mac_addr($mac_address);

                $nic = VirtualE1000->new(
                    controllerKey    => 100,
                    backing          => $nic_backing_info,
                    key              => $key,
                    unitNumber       => $unit_num,
                    addressType      => 'Manual',
                    connectable      => $vd_connect_info,
                    wakeOnLanEnabled => $iface->iface_pxe,
                    macAddress       => $iface->iface_mac_addr,
                    deviceInfo       => $desc,
                );

                $nic_conf_spec = VirtualDeviceConfigSpec->new(
                    device => $nic,
                    operation => VirtualDeviceConfigSpecOperation->new('add')
                );

                $key++;
                $unit_num++;
                push @network_conf, $nic_conf_spec;
            }
        }
    };
    if ($@) {
        $errmsg = 'Error creating the virtual machine network configuration: ' . $@;
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    return @network_conf;
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
    # TODO : search from begin entity datacenter view

    my $host_view = $self->findEntityView(
                        view_type   => 'HostSystem',
                        hash_filter => {
                            'hardware.systemInfo.uuid' => $host->vsphere5_uuid
                    });

    my $host_vms = $host_view->vm;
    my @vms;
    my @vm_ids;
    my @unk_vm_uuids;

    foreach my $vm (@$host_vms) {
        my $uuid = $self->getView(mo_ref => $vm)->config->uuid;

        my $e;
        eval {
            $e = Entity::Host::VirtualMachine::Vsphere5Vm->find(hash => { vsphere5_uuid => $uuid });
            push @vms, $e;
            push @vm_ids, $e->id;
        };
        if($@) {
            push @unk_vm_uuids, $uuid;
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

    my $vm_uuid = $args{host}->vsphere5_uuid;
    my $vm_view;
    eval {
        $vm_view = $self->findEntityView(
                       view_type    => 'VirtualMachine',
                       hash_filter  => {
                           'config.uuid' => $vm_uuid,
                       },
                   );
    };
    if ($@) {
        throw Kanopya::Exception(error => "VM <".$args{host}->id."> not found in infrastructure");
    }

    return {
        state      => $vm_view->runtime->powerState,
        hypervisor => $self->getView($vm_view->host)->name,
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

    my $details;
    eval {
        $details =  $self->getVMDetails(%args);
    };

    my $state_map = {
        'suspended'  => 'pend',
        'poweredOn'  => 'runn',
        'poweredOff' => 'shut',
    };

    return {
        state      => $state_map->{ $details->{state} } || 'fail',
        hypervisor => $details->{hypervisor},
    };
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

1;