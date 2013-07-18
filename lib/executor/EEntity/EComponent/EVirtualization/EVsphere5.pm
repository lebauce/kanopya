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
use Entity::Host::Hypervisor::Vsphere5Hypervisor;

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

    General::checkParams(args => \%args,
        required => [ 'host_view'],
        optional => {
            'diskless'         => 0,
            'container_access' => undef,
            'repository_name'  => undef,
        }
    );

    $self->negociateConnection();

    if ($args{diskless}) {
        # use existing datastore to store vm files
        my $datastore = pop @{ $self->getViews(mo_ref_array => $args{host_view}->datastore) };
        $log->debug('Diskless VM, use existing datastore ' . $datastore->name . ' to store VM\'s files');
        return $datastore->name;
    }

    my $container_access_ip = $args{container_access}->container_access_ip;
    my $export_full_path    = $args{container_access}->container_access_export;
    my @export_path         = split (':', $export_full_path);

    my $nas_vol_spec = HostNasVolumeSpec->new(accessMode => 'readWrite',
            remoteHost => $container_access_ip,
            localPath  => $args{repository_name},
            remotePath => $export_path[1],
       );

    my $host_ds_sys = $self->getView(mo_ref => $args{host_view}->configManager->datastoreSystem);
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
    my $guest_id   = 'debian6_64Guest';

    $log->info('Start host on < hypervisor '. $hypervisor->id.' >');

    if (not defined $hypervisor) {
        my $errmsg = "Cannot add node in cluster ".$host->getClusterId().", no hypervisor available";
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    my $cluster     = Entity->get(id => $host->getClusterId());
    my $diskless    = $cluster->cluster_boot_policy ne Manager::HostManager->BOOT_POLICIES->{virtual_disk};
    my $disk_params = $cluster->getManagerParameters(manager_type => 'DiskManager');
    my $host_params = $cluster->getManagerParameters(manager_type => 'HostManager');
    my $datacenter  = Entity::Component::Vsphere5::Vsphere5Datacenter->get(
                          id => $hypervisor->vsphere5_datacenter_id
                      );

    # retrieve views
    my $datacenter_view = $self->findEntityView(view_type   => 'Datacenter',
                                             hash_filter => {
                                                 name => $datacenter->vsphere5_datacenter_name
                                             });
    my $host_view = $self->findEntityView(view_type   => 'HostSystem',
                     hash_filter => {
                         'hardware.systemInfo.uuid' => $hypervisor->vsphere5_uuid
                     },
                     begin_entity => $datacenter_view,
                 );

    my %host_conf = ();
    if (not $diskless) {
        my $container_access = Entity::ContainerAccess->get(id => $disk_params->{container_access_id});

        # register repo in kanopya & vsphere
        my $repository = $self->addRepository(container_access => $container_access);
        $self->addDatastore(
            container_access => $container_access,
            repository_name  => $repository->repository_name,
            host_view        => $host_view,
        );

        $host_conf{datastore}  = $repository->repository_name;
        $host_conf{image_type} = $disk_params->{image_type};
    }
    else {
        $host_conf{datastore}  = $self->addDatastore(
            host_view => $host_view,
            diskless  => $diskless,
        );
    }

    my @ifaces = $args{host}->getIfaces();
    %host_conf = (
        %host_conf,
        hostname   => $host->node->node_hostname,
        guest_id   => $guest_id,
        img_name   => $host->getNodeSystemimage->systemimage_name,
        img_size   => $host->getNodeSystemimage->getContainer->container_size,
        diskless   => $diskless,
        memory     => $host_params->{ram},
        cores      => $host_params->{core},
        network    => 'VM Network',
    );

    $log->debug('new VM configuration parameters: ');
    $log->debug(Dumper \%host_conf);
    $host_conf{ifaces} = \@ifaces;
    $log->debug('Ifaces => ' . scalar @ifaces);

    # create the VM
    my $vm_config_spec = $self->createVmSpec(
                      host_conf       => \%host_conf,
                      host_view       => $host_view,
                      datacenter_view => $datacenter_view,
                  );
    my $vm_folder_view = $self->getView(mo_ref => $datacenter_view->vmFolder);
    my $comp_res_view  = $self->getView(mo_ref => $host_view->parent);

    my $vm_mor;
    eval {
        $vm_mor = $vm_folder_view->CreateVM(
            config => $vm_config_spec,
            pool   => $comp_res_view->resourcePool,
            host   => $host_view,
        );
    };
    if ($@) {
        my $errmsg = 'Error while creating the virtual machine on host '. $hypervisor->id . ' : '.$@;
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    my $vm_view = $self->getView(mo_ref => $vm_mor);

    # rollback
    if (exists $args{erollback} and defined $args{erollback}) {
        $args{erollback}->add(
            function   => $self->can('removeVm'),
            parameters => [ $self, 'host', $host, 'vm_view', $vm_view ]
        );
    }

    # power on vm
    eval {
        $vm_view->PowerOnVM;

        $self->promoteVm(
            host          => $host->_entity,
            vm_uuid       => $vm_view->config->uuid,
            hypervisor_id => $hypervisor->id,
            guest_id      => $guest_id,
        );
    };
    if ($@) {
        my $errmsg = 'Error while powering on VM ' . $host->id . ' : ' . $@;
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}

=pod

=begin classdoc

Create a VM specification on a vSphere host

@param host_conf the new vm configuration

=end classdoc

=cut

sub createVmSpec {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host_conf', 'datacenter_view', 'host_view']);

    my %host_conf = %{$args{host_conf}};
    my $ds_path   = '['.$host_conf{datastore}.']';
    my $host_view = $args{host_view};
    my $datacenter_view = $args{datacenter_view};
    my @vm_devices;

    #Generate vm's devices specifications
    my $controller_spec = $self->create_conf_spec();
    push @vm_devices, $controller_spec->{ide}, $controller_spec->{pci};

    if (not $host_conf{diskless}) {
        my $disk_conf_spec = $self->create_virtual_disk(
            controller_key => $controller_spec->{ide}->device->key,
            path           => $ds_path . ' ' . $host_conf{img_name} . '.' . $host_conf{image_type},
            disksize       => $host_conf{img_size}
        );
        push(@vm_devices, $disk_conf_spec);
    }

    my @net_settings = $self->get_network(
                           controller_key   => $controller_spec->{pci}->device->key,
                           network_name     => $host_conf{network},
                           ifaces           => $host_conf{ifaces},
                           host_view        => $host_view,
                           dc_view          => $datacenter_view,
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

    return $vm_config_spec;
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
        my $dc_name    = $host->hypervisor->vsphere5_datacenter->vsphere5_datacenter_name;

        #get views
        my $dc_view = $self->findEntityView(
                          view_type   => 'Datacenter',
                          hash_filter => {
                              name => $dc_name,
                          },
                      );
        my $vm_view = $self->findEntityView(
                          view_type    => 'VirtualMachine',
                          hash_filter  => {
                              'config.uuid' => $host->vsphere5_uuid,
                          },
                          begin_entity => $dc_view,
                      );

        # scale VM cpu
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
        my $dc_name    = $host->hypervisor->vsphere5_datacenter->vsphere5_datacenter_name;

        #get views
        my $dc_view = $self->findEntityView(
                          view_type   => 'Datacenter',
                          hash_filter => {
                              name => $dc_name,
                          },
                      );
        my $vm_view = $self->findEntityView(
                          view_type    => 'VirtualMachine',
                          hash_filter  => {
                              'config.uuid' => $host->vsphere5_uuid,
                          },
                          begin_entity => $dc_view,
                      );

        # scale VM memory
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
    }
    else {
        $errmsg = 'The host type: ' . ref $host . ' is not handled by this manager';
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}

sub migrateHost {
    throw Kanopya::Exception::NotImplemented();
}

sub resubmitNode {
    throw Kanopya::Exception::NotImplemented();
}

=pod

=begin classdoc

Terminate a host

=end classdoc

=cut

sub halt {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    my $dc_name = $args{host}->hypervisor->vsphere5_datacenter->vsphere5_datacenter_name;

    # get views
    my $dc_view = $self->findEntityView(
                      view_type   => 'Datacenter',
                      hash_filter => {
                          name => $dc_name,
                      },
                  );
    my $vm_view = $self->findEntityView(
                      view_type    => 'VirtualMachine',
                      hash_filter  => {
                          'config.uuid' => $args{host}->vsphere5_uuid,
                      },
                      begin_entity => $dc_view,
                  );

    # stop vm
    $vm_view->PowerOffVM;
}

sub stopHost {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    my $host = $args{host};

    my $dc_name = $host->hypervisor->vsphere5_datacenter->vsphere5_datacenter_name;

    # get views
    my $dc_view = $self->findEntityView(
                      view_type   => 'Datacenter',
                      hash_filter => {
                          name => $dc_name,
                      },
                  );
    my $vm_view = $self->findEntityView(
                      view_type    => 'VirtualMachine',
                      hash_filter  => {
                          'config.uuid' => $host->vsphere5_uuid,
                      },
                      begin_entity => $dc_view,
                  );

    # Dissociate disks from VM + delete VM
    $self->removeVm(host => $host, vm_view => $vm_view, rename_disk => 1);
}

sub releaseHost {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ "host" ]);

    $args{host}->delete();
}

=pod

=begin classdoc

Dissociate disks from VM to prevent their removal on VM destroy, rename descriptor file then destroy VM

=end classdoc

=cut

sub removeVm {
    my ($self,%args) = @_;

    General::checkParams(
        args     => \%args,
        required => [ 'host', 'vm_view' ],
        optional => { 'rename_disk' => 0 }
    );

    $self->dissociateDisk(
        host => $args{host},
        vm_view => $args{vm_view},
        rename_disk => $args{rename_disk}
    );

    # delete vm
    $args{vm_view}->Destroy;
}

sub dissociateDisk {
    my ($self,%args) = @_;

    General::checkParams(
        args     => \%args,
        required => [ 'host', 'vm_view' ],
        optional => { 'rename_disk' => 0 }
    );

    my $host = $args{host};
    my $vm_view = $args{vm_view};

    my $devices = $vm_view->config->hardware->device;
    my @disks_remove_spec;
    foreach my $device (@$devices) {
        if ( $device->isa('VirtualDisk') ) {
            my $disk_remove_spec = VirtualDeviceConfigSpec->new(
                operation => VirtualDeviceConfigSpecOperation->new('remove'),
                device    => $device
            );
            push @disks_remove_spec, $disk_remove_spec;
        }
    }

    if (scalar @disks_remove_spec) {
        $log->debug('Dissociate disks of vm ' . $host->id);

        my $disk_files_info = $vm_view->layoutEx->file;
        my $vm_config_spec = VirtualMachineConfigSpec->new(
                                 deviceChange => \@disks_remove_spec
                             );
        eval {
                $vm_view->ReconfigVM(
                    spec => $vm_config_spec,
                );
        };
        if ($@) {
            $errmsg = 'Error in virtual disks removal on VM ' . $host->node->node_hostname.': '.$@;
            throw Kanopya::Exception::Internal(error => $errmsg);
        }

        if ($args{rename_disk}) {
            # Work around to rename systemimage disk file because vmware rename disk file to descriptor file
            my $systemimage_name = $host->getNodeSystemimage->systemimage_name;
            my $cluster     = Entity->get(id => $host->getClusterId());
            my $disk_params = $cluster->getManagerParameters(manager_type => 'DiskManager');
            my $container_access = Entity::ContainerAccess->get(id => $disk_params->{container_access_id});
            my $image_type = $disk_params->{image_type};

            my $econtext = $self->_host->getEContext;
            my $e_container_access = EEntity->new(entity => $container_access);

            # get disk filename
            (my $disk_file_info) = grep {
                ($_->type eq 'diskExtent') and ($_->name =~ m/$systemimage_name/)
            } @$disk_files_info;
            my $disk_filename = (split(/] /,$disk_file_info->name))[1];

            # rename disk file
            eval {
                $log->debug("Rename systemimage file to it's original value");

                my $mountpoint = $e_container_access->mount(econtext => $econtext);
                my $command = 'mv ' . $mountpoint . '/' . $disk_filename . ' '
                               . $mountpoint . '/' . $systemimage_name . '.' . $image_type;
                $log->debug("command = $command");
                $econtext->execute(command => $command);
                $e_container_access->umount(econtext => $econtext);
            };
            if ($@) {
                $errmsg = 'Error in systemimage rename on VM ' . $host->node->node_hostname.': '.$@;
                throw Kanopya::Exception::Internal(error => $errmsg);
            }
        }
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

    return {
        ide => $controller_ide_spec,
        pci => $controller_pci_spec
    };
}

sub create_virtual_disk {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'controller_key', 'path', 'disksize']);

    my $disk_vm_dev_conf_spec;
    my $disk_backing_info;
    my $disk;

    eval {
        $disk_backing_info = VirtualDiskFlatVer2BackingInfo->new(
            diskMode => 'persistent',
            fileName => $args{path},
            split    => 0
        );

        $disk = VirtualDisk->new(
            backing       => $disk_backing_info,
            controllerKey => $args{controller_key},
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

    General::checkParams(
        args => \%args,
        required => [ 'controller_key', 'network_name', 'host_view', 'dc_view' ]
    );

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
            IFACE:
            for my $iface (@{ $args{ifaces} }) {
                # skip ifaces without ip address
                eval {
                    $iface->getIPAddr();
                };
                next IFACE if ($@);

                # TODO : register vlan on port group or synchronize netconfs
                $vlan = undef;
                @vlans = $iface->getVlans();
                if (scalar @vlans) {
                    $vlan = pop @vlans;
                }

                # TODO : portGroup/Vlan on an hypervisor + same name on all hypervisors of datacenter
                $nic_backing_info = VirtualEthernetCardNetworkBackingInfo->new(
                    deviceName => $network_name, # network to which interface will be connected
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

                $nic = VirtualE1000->new(
                    controllerKey    => $args{controller_key},
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
        $args{host} = Entity::Host::Hypervisor::Vsphere5Hypervisor->get(id => $args{host_id});
        delete $args{host_id};
    }

    my $dc_name = $args{host}->vsphere5_datacenter->vsphere5_datacenter_name;
    my $hv_uuid = $args{host}->vsphere5_uuid;

    # get views
    my $dc_view = $self->findEntityView(
                      view_type   => 'Datacenter',
                      hash_filter => {
                          name => $dc_name,
                      },
                  );
    my $host_view = $self->findEntityView(
                              view_type    => 'HostSystem',
                              hash_filter  => {
                                  'hardware.systemInfo.uuid' => $hv_uuid
                              },
                              begin_entity => $dc_view,
                          );
    my $host_vms = $self->getViews(mo_ref_array => $host_view->vm);
    my @vms;
    my @vm_ids;
    my @unk_vm_uuids;

    foreach my $vm (@$host_vms) {
        my $uuid = $vm->config->uuid;

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

    my $state = $vm_view->runtime->connectionState->val ne 'connected'
                    ? 'error' : $vm_view->runtime->powerState->val;
    # TODO : transition state MIGRATING using WaitForUpdatesEx

    return {
        state      => $state,
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
        'error'      => 'fail',
        # 'migrating' => 'migr',
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