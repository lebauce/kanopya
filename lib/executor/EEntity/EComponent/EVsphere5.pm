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

package EEntity::EComponent::EVsphere5;

use base "EEntity::EComponent";
use base "EManager::EHostManager::EVirtualMachineManager";

use strict;
use warnings;

use VMware::VIRuntime;
use Vsphere5Datacenter;
use Vsphere5Repository;
use Entity;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;

my $log = get_logger("executor");
my $errmsg;

sub new {
    my ($self,%args) = @_;

    $self->SUPER::new();

    $self->connect(\%args);
}

######################
# connection methods #
######################

=head2 connect

    Desc: Connect to a vCenter instance
    Args: $login, $pwd
 
=cut

sub connect {
    my ($self,%args) = @_; 

    General::checkParams(args => \%args, required => ['user_name', 'password', 'url']);

    eval {
        Util::connect($args{url}, $args{user_name}, $args{password});
    };
    if ($@) {
        $errmsg = 'Could not connect to vCenter server: '.$@;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}

=head2 disconnect

    Desc: End the vSphere session

=cut

sub disconnect {
    eval {
        Util::disconnect();
    };
    if ($@) {
        $errmsg = 'Could not disconnect to vCenter server: '.$@;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}

#########################
# configuration methods #
#########################

=head2 addRepository

    Desc: Register a new repository for an host in Vsphere
    Args: $repository_name, $container_access 
    Return: newly created $repository object

=cut

sub addRepository {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['repository_name', 'container_access']);

    my $container_access    = $args{container_access};
    my $container_access_ip = $container_access->container_access_ip;
    my $export_full_path    = $container_access->container_access_export;
    my @export_path         = split (':', $export_full_path);

    #TODO check if a vsphere connection is open
    my $view = Vim::find_entity_view(view_type => 'HostSystem');

    my $datastore = HostNasVolumeSpec->new( accessMode => 'readWrite',
                                            remoteHost => $container_access_ip,
                                            localPath  => $args{repository_name},
                                            remotePath => $export_path[1],
                );

    my $dsmv = $view->{vim}->get_view(mo_ref=>$view->configManager->datastoreSystem);

    eval {
        $dsmv->CreateNasDatastore(spec => $datastore);
    };
    if ($@) {
        $errmsg = 'Could not attach the datastore to the host: '.$@."\n";
        throw Kanopya::Exception::Internal(error => $errmsg);
    } else {
        print "success! \n";
    }
}

#########################
# manipulation methods ##
#########################

=head2 startHost

    Desc: Create and start a vm

=cut

sub startHost {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['hypervisor', 'host' ]);

    my $host       = $args{host};
    my $hypervisor = $args{hypervisor};
    my $guest_id   = 'debian6Guest';

    if (!defined $hypervisor) {
        my $errmsg = "Cannot add node in cluster ".$args{host}->getClusterId().", no hypervisor available";
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    
    my %host_conf;
    my $cluster     = Entity->get(id => $host->getClusterId());
    my $disk_params = $cluster->getManagerParameters(manager_type => 'disk_manager');
    my $host_params = $cluster->getManagerParameters(manager_type => 'host_manager');
    my $repository  = $self->getRepository(
                          container_access_id => $disk_params->{container_access_id}
                      );
    my $datacenter  = Vsphere5Datacenter->find(hash => { 
                          vsphere5_datacenter_id => $hypervisor->vsphere5_datacenter_id
                      });

    
    $host_conf{hostname}   = $host->host_hostname;
    $host_conf{hypervisor} = $hypervisor->host_hostname;
    $host_conf{datacenter} = $datacenter->vsphere5_datacenter_name;
    $host_conf{guest_id}   = $guest_id;
    $host_conf{datastore}  = $repository->repository_name;
    $host_conf{memory}     = $host_params->{ram};
    $host_conf{cores}      = $host_params->{core};
    $host_conf{network}    = 'VM Network';

    #Create vm in vsphere
    $self->createVm(host_conf => \%host_conf);

    #Declare the vsphere5 vm in Kanopya
    $self->addVM(
        host     => $host,
        guest_id => $guest_id,
    );

    #Power on the VM
    eval {
        $self->powerOnVm(hypervisor => $hypervisor, vm => $host);
    };
    if ($@) {
        $errmsg  = 'Could not launch newly created vm '.$host->host_hostname;
        $errmsg .= ': '.$@;
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}


=head2 createVm

    Desc: Create a new VM on a vSphere host 

=cut

sub createVm {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host_conf']);

    my %host_conf = %{$args{host_conf}};
    my $ds_path   = '['.$host_conf{datastore}.']';
    my $host_view;
    my $datacenter_view;
    my $vm_folder_view;
    my $comp_res_view;
    my @vm_devices;

    #retrieve host view
    eval {
        $host_view = Vim::find_entity_view(view_type => 'HostSystem',
                                           filter    => {
                                               'name' => $host_conf{hypervisor}
                                          });
    };
    if ($@) {
        $errmsg  = 'Error finding hypervisor '.$host_conf{hypervisor}.' on vSphere';
        $errmsg .= ': '.$@;
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    #retrieve datacenter view
    eval {
        $datacenter_view = Vim::find_entity_view(view_type => 'Datacenter',
                                                 filter    => { 
                                                     name => $host_conf{datacenter}
                                                });
    };
    if ($@) {
        $errmsg  = 'Error finding datacenter '.$host_conf{datacenter}.' on vSphere';
        $errmsg .= ': '.$@;
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    #Generate vm's devices specifications
    my $controller_vm_dev_conf_spec = create_conf_spec();

    push(@vm_devices, $controller_vm_dev_conf_spec);

    my $disk_vm_dev_conf_spec =
        create_virtual_disk(ds_path => $ds_path, disksize => '4294999');

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
    eval {
        $vm_folder_view = Vim::get_view(mo_ref => $datacenter_view->vmFolder);
    };
    if ($@) {
        $errmsg  = 'Error finding the vm folder on vSphere';
        $errmsg .= ': '.$@;
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    #retrieve the host parent view
    eval {
        $comp_res_view  = Vim::get_view(mo_ref => $host_view->parent);
    };
    if ($@) {
        $errmsg  = 'Error finding the parent managed entity of the host view';
        $errmsg .= ': '.$@;
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    #finally create the VM
    eval { 
        $vm_folder_view->CreateVM(config => $vm_config_spec,
                                  pool   => $comp_res_view->resourcePool);
    };
    if ($@) {
        $errmsg  = 'Error creating the virtual machine on host '.$host_conf{hypervisor};;
        $errmsg .= ': '.$@;
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

}

=head2 powerOnVm

    Desc: start a VM registerd on vSphere

=cut

sub powerOnVm {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'hypervisor', 'vm']);

    my $host_name = $args{hypervisor}->host_hostname;
    my $vm_name   = $args{vm}->host_hostname;

    #get the HostSystem view
    my $host_view = Vim::find_entity_view(view_type => 'HostSystem',
                                          filter    => {
                                              'name' => $host_name}
                                         );
    my $host_vms = $host_view->vm;
 
    #maybe find a better way to do that? 
    foreach my $vm (@$host_vms) {
        my $guest = Vim::get_view (mo_ref => $vm);
        if ($guest->name eq $vm_name) {
            $guest->PowerOnVM();
        }
    }
}

sub create_conf_spec {
    my $controller =
        VirtualBusLogicController->new(key => 0,
                                       device => [0],
                                       busNumber => 0,
                                       sharedBus => VirtualSCSISharing->new('noSharing')
        );

    my $controller_vm_dev_conf_spec =
        VirtualDeviceConfigSpec->new(
            device => $controller,
            operation => VirtualDeviceConfigSpecOperation->new('add')
        );

    return $controller_vm_dev_conf_spec;
}

sub create_virtual_disk {
   my %args = @_;
   my $ds_path  = $args{ds_path};
   my $disksize = $args{disksize};

   my $disk_backing_info =
       VirtualDiskFlatVer2BackingInfo->new(diskMode => 'persistent',
                                           fileName => $ds_path);

   my $disk = VirtualDisk->new(backing       => $disk_backing_info,
                               controllerKey => 0,
                               key           => 0,
                               unitNumber    => 0,
                               capacityInKB  => $disksize);

   my $disk_vm_dev_conf_spec =
       VirtualDeviceConfigSpec->new(
           device        => $disk,
           fileOperation => VirtualDeviceConfigSpecFileOperation->new('create'),
           operation     => VirtualDeviceConfigSpecOperation->new('add')
       );

   return $disk_vm_dev_conf_spec;
}

sub get_network {
    my %args         = @_;
    my $network_name = $args{network_name};
    my $poweron      = $args{poweron};
    my $host_view    = $args{host_view};
    my $network      = undef;
    my $unit_num     = 1;  # 1 since 0 is used by disk

    if($network_name) {
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
    # default network will be used
    return (error => 2);
}

sub DESTROY {
    my $self = shift;

    $self->disconnect();
}

1;
