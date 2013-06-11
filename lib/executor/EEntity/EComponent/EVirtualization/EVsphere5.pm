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

use VMware::VIRuntime;
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
    my $guest_id   = 'debian6_64Guest';

    $log->info('Start host on < hypervisor '. $hypervisor->id.' >');

    if (!defined $hypervisor) {
        my $errmsg = "Cannot add node in cluster ".$args{host}->getClusterId().", no hypervisor available";
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    my %host_conf;
    my $cluster     = Entity->get(id => $host->getClusterId());
    my $image       = $args{host}->getNodeSystemimage();
    #TODO fix this way to get image disk file type
    my $image_name  = $image->systemimage_name;
    my $image_size  = $image->container->container_size;
    my $disk_params = $cluster->getManagerParameters(manager_type => 'DiskManager');
    my $image_type = $disk_params->{image_type};
    my $host_params = $cluster->getManagerParameters(manager_type => 'HostManager');
    my $datacenter  = Entity::Component::Vsphere5::Vsphere5Datacenter->find(hash => {
                          vsphere5_datacenter_id => $hypervisor->vsphere5_datacenter_id
                      });

    my $repo = Entity::Repository->find(hash => {
        container_access_id => $disk_params->{container_access_id},
        virtualization_id   => $self->id
    });
    my $container_access = Entity::ContainerAccess->get(id => $repo->container_access_id);

    # register repo in kanopya
    my $repository  = $self->_entity->addRepository(
        virtualization_id   => $self->id,
        repository_name     => $repo->repository_name,
        container_access_id => $repo->container_access_id,
    );
    # register repo in VSphere
    $self->addRepository(
        hypervisor       => $hypervisor,
        repository_name  => $repo->repository_name,
        container_access => $container_access,
    );

    $host_conf{hostname}   = $host->node->node_hostname;
    $host_conf{hypervisor} = $hypervisor->node->node_hostname;
    $host_conf{datacenter} = $datacenter->vsphere5_datacenter_name;
    $host_conf{guest_id}   = $guest_id;
    $host_conf{datastore}  = $repository->repository_name;
    $host_conf{img_name}   = $image_name;
    $host_conf{image_type} = $image_type;
    $host_conf{img_size}   = $image_size;
    $host_conf{memory}     = $host_params->{ram};
    $host_conf{cores}      = $host_params->{core};
    $host_conf{network}    = 'VM Network';

    $log->debug('new VM configuration parameters: ');
    $log->debug(Dumper \%host_conf);

    #Create vm in vsphere
    $self->createVm(host_conf => \%host_conf);

    #Declare the vsphere5 vm in Kanopya
    $self->addVM(
        host     => $host->_entity,
        guest_id => $guest_id,
        uuid     => $host->vsphere5_uuid,
        hypervisor_id => $hypervisor->id,
    );

    #Power on the VM
    #We retrieve a view of the newly created VM
    my $hypervisor_hash_filter = {name => $hypervisor->node->node_hostname};
    my $hypervisor_view        = findEntityView(
                                    view_type   => 'HostSystem',
                                    hash_filter => $hypervisor_hash_filter,
                                 );
    my $vm_hash_filter        = {name => $host->node->node_hostname};
    my $vm_view               = findEntityView(
                                    view_type    => 'VirtualMachine',
                                    hash_filter  => $vm_hash_filter,
                                    begin_entity => $hypervisor_view,
                                );
    #Power On
    $vm_view->PowerOnVM();
}

=pod

=begin classdoc

Create a new VM on a vSphere host

@param host_conf the new vm configuration

=end classdoc

=cut

sub createVm {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host_conf']);

    my %host_conf = %{$args{host_conf}};
    my $ds_path   = '['.$host_conf{datastore}.']';
    my $img_name  = $host_conf{img_name};
    my $image_type = $host_conf{image_type};
    my $img_size  = $host_conf{img_size};
    my $path      = $ds_path . ' ' . $img_name . '.' . $image_type;
    my $host_view;
    my $datacenter_view;
    my $vm_folder_view;
    my $comp_res_view;
    my @vm_devices;

    $log->info('trying to get Hypervisor ' .$host_conf{hypervisor}. ' view from vsphere');

    #retrieve host view
    $host_view = $self->findEntityView(view_type   => 'HostSystem',
                                       hash_filter => {
                                           'name' => $host_conf{hypervisor},
                                       });

    #retrieve datacenter view
    $datacenter_view = $self->findEntityview(view_type   => 'Datacenter',
                                             hash_filter => {
                                                 name => $host_conf{datacenter}
                                             });

    #Generate vm's devices specifications
    my $controller_vm_dev_conf_spec = create_conf_spec();
    push(@vm_devices, $controller_vm_dev_conf_spec);

    my $disk_vm_dev_conf_spec = create_virtual_disk(path => $path, disksize => $img_size);
    push(@vm_devices, $disk_vm_dev_conf_spec);

    my %net_settings = get_network(network_name => $host_conf{network},
                                    poweron      => 0,
                                    host_view    => $host_view);
    push(@vm_devices, $net_settings{network_conf});

    my $files = VirtualMachineFileInfo->new(logDirectory      => undef,
                                            snapshotDirectory => undef,
                                            suspendDirectory  => undef,
                                            vmPathName        => $ds_path);

    my $vm_config_spec = VirtualMachineConfigSpec->new(
                             name         => $host_conf{hostname},
                             memoryMB     => $host_conf{memory},
                             files        => $files,
                             numCPUs      => $host_conf{cores},
                             guestId      => $host_conf{guest_id},
                             deviceChange => \@vm_devices);

    #retrieve the vm folder from vsphere inventory
    $vm_folder_view = $self->getView(mo_ref => $datacenter_view->vmFolder);

    #retrieve the host parent view
    $comp_res_view  = $self->getView(mo_ref => $host_view->parent);

    #finally create the VM
    eval {
        $vm_folder_view->CreateVM(config => $vm_config_spec,
                                  pool   => $comp_res_view->resourcePool);
    };
    if ($@) {
        $errmsg = 'Error creating the virtual machine on host '.$host_conf{hypervisor}.': '.$@;
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

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

    General::checkParams(args => \%args, required => ['host','memory']);

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
    my $controller;
    my $controller_vm_dev_conf_spec;

    eval {
        $controller =
            VirtualLsiLogicController->new(key => 0,
                                           device => [0],
                                           busNumber => 0,
                                           sharedBus => VirtualSCSISharing->new('noSharing')
            );

        $controller_vm_dev_conf_spec =
            VirtualDeviceConfigSpec->new(
                device => $controller,
                operation => VirtualDeviceConfigSpecOperation->new('add')
            );
    };
    if ($@) {
        $errmsg = 'Error creating the virtual machine controller configuration: '.$@;
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    return $controller_vm_dev_conf_spec;
}

sub create_virtual_disk {
    my %args     = @_;
    my $path     = $args{path};
    my $disksize = $args{disksize};

    my $disk_vm_dev_conf_spec;
    my $disk_backing_info;
    my $disk;

    eval {
        $disk_backing_info =
           VirtualDiskFlatVer2BackingInfo->new(diskMode => 'persistent',
                                               fileName => $path);

        $disk = VirtualDisk->new(backing       => $disk_backing_info,
                                   controllerKey => 0,
                                   key           => 0,
                                   unitNumber    => 0,
                                   capacityInKB  => $disksize);

        $disk_vm_dev_conf_spec =
           VirtualDeviceConfigSpec->new(
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
    my %args         = @_;
    my $network_name = $args{network_name};
    my $poweron      = $args{poweron};
    my $host_view    = $args{host_view};
    my $network      = undef;
    my $unit_num     = 1;  # 1 since 0 is used by disk

    eval {
        if($network_name) {
        #TODO Use get view from an Mother entity + Eval{};
            my $network_list = Vim::get_views(mo_ref_array => $host_view->network);
            foreach (@$network_list) {
                if($network_name eq $_->name) {
                    $network             = $_;
                    my $nic_backing_info =
                        VirtualEthernetCardNetworkBackingInfo->new(
                            deviceName => $network_name,
                            network    => $network
                        );

                    my $vd_connect_info =
                        VirtualDeviceConnectInfo->new(allowGuestControl => 1,
                                                      connected         => 0,
                                                      startConnected    => $poweron);

                    my $nic = VirtualPCNet32->new(backing     => $nic_backing_info,
                                                  key         => 0,
                                                  unitNumber  => $unit_num,
                                                  addressType => 'generated',
                                                  connectable => $vd_connect_info);

                    my $nic_vm_dev_conf_spec =
                        VirtualDeviceConfigSpec->new(
                            device => $nic,
                            operation => VirtualDeviceConfigSpecOperation->new('add')
                        );

                    return (error => 0, network_conf => $nic_vm_dev_conf_spec);
                }
            }

            if (!defined($network)) {
                # no network found
                return (error => 1);
            }
        }
    };
    if ($@) {
        $errmsg = 'Error creating the virtual machine network configuration: '.$@;
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    # default network will be used
    return (error => 2);
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

1;