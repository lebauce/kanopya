#    Copyright © 2014 Hedera Technology SAS
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
#
# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod
=begin classdoc

The AWS component provides access and management of Amazon Web Services.
It is modeled after the OpenStack component, therefore it is at the same time
a data holder for accessing AWS infrastructure (for one account) 
and it offers methods for the manipulation of said infrastructure.

API calls are encapsulated within AWS::API (general means of access) and
AWS::EC2 (individual API calls for EC2).

# This component is able to synchronise the existing infrastructure to the HCM api, and load
# the available parameters/option for each AWSW services.

It implements the four HCM management interfaces for IaaS components:
VirtualMachineManager, StorageManager, BootManager, NetworkManager.

=end classdoc
=cut

package Entity::Component::Virtualization::AwsAccount;
use parent Entity::Component::Virtualization;
use parent Manager::HostManager::VirtualMachineManager;
use parent Manager::StorageManager;
use parent Manager::BootManager;
use parent Manager::NetworkManager;

use strict;
use warnings;

use AWS::API;
use AWS::EC2;
use AwsInstanceType;
use CapacityManagement;
use ClassType::ServiceProviderType::ClusterType;
#use Entity::Host::Hypervisor::OpenstackHypervisor;
#use Entity::Host::VirtualMachine::OpenstackVm;
use Entity::Masterimage::AwsMasterimage;
#use Entity::Systemimage::CinderSystemimage;
#use Entity::Node;
#use ParamPreset;
use Kanopya::Exceptions;

#use OpenStack::Port;
#use OpenStack::Volume;
#use OpenStack::Server;
#use OpenStack::Infrastructure;

#use Hash::Merge;
use Data::Dumper;
use Log::Log4perl "get_logger";
my $log = get_logger("");
use TryCatch;

use constant ATTR_DEF => {
    executor_component_id => {
        label        => 'Workflow manager',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^[0-9\.]*$',
        is_mandatory => 1,
        is_editable  => 0
    },
    api_access_key => {
        label        => 'AWS access key',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1
    },
    api_secret_key => {
        label        => 'AWS secret key',
        type         => 'password',
        pattern      => '^.*$',
        is_mandatory => 0
    },
    region => {
        label        => 'AWS region',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 0
    },
    host_type => {
        is_virtual => 1
    }
};

sub getAttrDef { return ATTR_DEF; }

my $vm_states = { running         => 'in',
                  pending         => 'in',
                  'shutting-down' => 'out',
                  terminated      => 'out',
                  stopping        => 'out',
                  stopped         => 'out'  };


=begin classdoc

Set the state for the node according to its AWS state

@param node (Entity::Node)
@param vm_info (Hashref) VM information hashref, including "state"

@return Hashref

=end classdoc
=cut

sub setNodeState {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['node', 'vm_info']);
    
    my $aws_state = $args{vm_info}{'state'};
    $args{node}->setState('state' => $vm_states->{$aws_state} . ':' . time());
}


=pod
=begin classdoc

@constructor

Override the parent constructor to store the credentials params
the the related param preset.

@return a class instance

=end classdoc
=cut

sub new {
    my ($class, %args) = @_;
    my $fields = ['api_access_key', 'api_secret_key'];

    General::checkParams(args => \%args, required => $fields);
                         
    unless (defined($args{region})) {
        $args{region} = 'eu-west-1';
    }

    my $self = $class->SUPER::new(%args);

    # Initialize the param preset entry used to store available configuration
    $self->param_preset(ParamPreset->new());
    
    foreach my $key (@$fields, 'region') {
        $self->{key} = $args{key};
    }

    return $self;
}

=pod
=begin classdoc

Lazily load an API object, so that it can be available for this instance. 

@return AWS::API instance for this account

=end classdoc
=cut

sub _api {
    my ($self) = @_;
    
    $self->{api} ||= AWS::API->new(aws_account => $self);
    
    return $self->{api};
}

=pod
=begin classdoc

Lazily load an EC2 object, so that it can be available for this instance. 

@return AWS::EC2 instance for this account

=end classdoc
=cut

sub _ec2 {
    my ($self) = @_;
    
    $self->{ec2} ||= AWS::EC2->new(api => $self->_api);
    
    return $self->{ec2};
}


#
#sub remove {
#    my ($self, %args) = @_;
#    $self->unregister();
#    $self->SUPER::remove();
#}
#
#sub unregister {
#    my ($self, %args) = @_;
#    my @spms = $self->service_provider_managers;
#    if (@spms) {
#        my $error = 'Cannot unregister OpenStack: Still used as "'
#                    . $spms[0]->manager_category->category_name
#                    . '" by cluster "'
#                    . $spms[0]->service_provider->label . '"';
#        throw Kanopya::Exception::Internal(error => $error);
#    }
#
#    my @sis = $self->systemimages;
#    if (@sis) {
#        my $error = 'Cannot unregister OpenStack: Still linked to a systemimage "'
#                    . $sis[0]->label . '"';
#        throw Kanopya::Exception::Internal(error => $error);
#    }
#
#    for my $vm ($self->hosts) {
#        if (defined $vm->node) {
#            $vm->node->delete;
#        }
#        $vm->delete;
#    }
#
#    for my $host ($self->hypervisors) {
#        if (defined $host->node) {
#            $host->node->delete;
#        }
#        $host->delete;
#    }
#
#    $self->removeMasterimages();
#}
#
#sub hostType {
#    my $self = shift;
#    return $self->label;
#}
#
#
#sub label {
#    my $self = shift;
#    return $self->SUPER::label . " " . $self->keystone_url  . " (" . $self->tenant_name . ")";
#}
#
#
#=pod
#=begin classdoc
#
#@return the network configuration used to check the availability of the openstack apis.
#
#=end classdoc
#=cut
#
#sub getNetConf {
#    my $self = shift;
#
#    my $conf = {
#        novncproxy => {
#            port => 6080,
#            protocols => ['tcp']
#        },
#        ec2 => {
#            port => 8773,
#            protocols => ['tcp']
#        },
#        compute_api => {
#            port => 8774,
#            protocols => ['tcp']
#        },
#        metadata_api => {
#            port => 8775,
#            protocols => ['tcp']
#        },
#        volume_api => {
#            port => 8776,
#            protocols => ['tcp']
#        },
#        glance_registry => {
#            port => 9191,
#            protocols => ['tcp']
#        },
#        image_api => {
#            port => 9292,
#            protocols => ['tcp']
#        },
#        keystone_service => {
#            port => 5000,
#            protocols => ['tcp']
#        },
#        keystone_admin => {
#            port => 35357,
#            protocols => ['tcp']
#        },
#        neutron => {
#            port => 9696,
#            protocols => ['tcp']
#        }
#    };
#
#    return $conf;
#}
#
#
#=pod
#=begin classdoc
#
#@return the manager params definition.
#
#=end classdoc
#=cut
#
#sub getManagerParamsDef {
#    my ($self, %args) = @_;
#
#    return {
#        %{ $self->SUPER::getManagerParamsDef },
#        flavor => {
#            label        => 'Flavor',
#            type         => 'enum',
#            pattern      => '^.*$',
#            is_mandatory => 1
#        },
#        availability_zone => {
#            label        => 'Availability Zone',
#            type         => 'enum',
#            pattern      => '^.*$',
#            is_mandatory => 1
#        },
#        hosting_tenant => {
#            label        => 'Project',
#            type         => 'enum',
#            pattern      => '^.*$',
#            is_mandatory => 1
#        },
#        network_tenant => {
#            label        => 'Project',
#            type         => 'enum',
#            pattern      => '^.*$',
#            is_mandatory => 1
#        },
#        volume_type => {
#            label        => 'Volume type',
#            type         => 'enum',
#            is_mandatory => 1,
#            # TODO:  Get the enum options from the available synchronized backend
#            options      => []
#        },
#        repository   => {
#            is_mandatory => 1,
#            label        => 'Repository',
#            type         => 'enum',
#        },
#        subnets => {
#            label        => 'Subnets',
#            is_mandatory => 1,
#            type         => 'relation',
#            relation     => 'multi',
#            is_editable  => 1,
#            options      => [],
#        },
#
#    };
#}
#
#
#=pod
#=begin classdoc
#
#Return the parameters definition available for the VirtualMachineManager api.
#
#@see <package>Manager::HostManager</package>
#
#=end classdoc
#=cut
#
#sub getHostManagerParams {
#    my $self = shift;
#    my %args = @_;
#
#    my $params = $self->getManagerParamsDef;
#    my $pp = $self->param_preset->load;
#
#    my $flavors = $params->{flavor};
#    my @flavor_names = map {$pp->{flavors}->{$_}->{name}} keys %{$pp->{flavors}};
#    $flavors->{options} = \@flavor_names;
#
#    my $zones = $params->{availability_zone};
#    my @zone_names = keys %{$pp->{zones}};
#    $zones->{options} = \@zone_names;
#
#    my @tenant_names = keys %{$pp->{tenants_name_id}};
#    my $tenants = $params->{hosting_tenant};
#    $tenants->{options} = \@tenant_names;
#
#    my $hash = {
#        flavor => $flavors,
#        availability_zone => $zones,
#        hosting_tenant => $tenants,
#    };
#
#    return $hash;
#}
#
#
#=pod
#=begin classdoc
#
#Check parameters that will be given to the VirtualMachineManager api methods.
#
#@see <package>Manager::HostManager</package>
#
#=end classdoc
#=cut
#
#sub checkHostManagerParams {
#    my ($self, %args) = @_;
#
#    General::checkParams(args => \%args, required => [ 'flavor', 'availability_zone', 'hosting_tenant' ]);
#}
#
#
#=pod
#=begin classdoc
#
#Return the parameters definition available for the DiskManager API.
#
#@see <package>Manager::StorageManager</package>
#
#=end classdoc
#=cut

#sub getStorageManagerParams {
#    my ($self, %args) = @_;
#
##    my $pp = $self->param_preset->load;
##    my $params = { volume_type => $self->getManagerParamsDef->{volume_type} };
##
##    for my $type_id (keys %{ $pp->{volume_types} }) {
##        push @{ $params->{volume_type}->{options} }, $pp->{volume_types}->{$type_id}->{name};
##    }
##
##    return $params;
#
#    return {};
#}


=pod
=begin classdoc

Check parameters that will be given to the DiskManager API methods.

@see <package>Manager::StorageManager</package>

=end classdoc
=cut

# NOTE MERGE : nearly the same as OpenStack
sub checkStorageManagerParams {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => []);

    # Workaround: Add a dummy boot_policy to fix missing boot_policy when
    #             when storage manager is not the HCMStorageManager.
    # TODO: Make the param boot_policy required for the HCMDeploymentManager boot manager params
    $args{boot_policy} = 'Boot from AWS image';

    return \%args;

}


#=pod
#=begin classdoc
#
#@return the network manager parameters as an attribute definition.
#
#@see <package>Manager::NetworkManager</package>
#
#=end classdoc
#=cut
#
#sub getNetworkManagerParams {
#    my ($self, %args) = @_;
#
#    my $params = $self->getManagerParamsDef;
#    my $pp = $self->param_preset->load;
#
#    my @tenant_names = keys %{$pp->{tenants_name_id}};
#    my $tenants = $params->{network_tenant};
#    $tenants->{options} = \@tenant_names;
#    $tenants->{reload} = 1;
#
#    my $hash = { network_tenant => $tenants };
#    if (defined $args{params}->{network_tenant}) {
#        my $tenant_id = $pp->{tenants_name_id}->{$args{params}->{network_tenant}};
#
#        my $subnets = $self->getManagerParamsDef->{subnets};
#        for my $network_id (@{ $pp->{tenants}->{$tenant_id}->{networks} }) {
#            my $network_name = $pp->{networks}->{$network_id}->{name};
#
#            for my $subnet_id (@{ $pp->{networks}->{$network_id}->{subnets} }) {
#                push @{ $subnets->{options} }, $pp->{subnets}->{$subnet_id}->{cidr} . " ($network_name)";
#            }
#        }
#        $hash->{subnets} = $subnets;
#    }
#    return $hash;
#}


=pod
=begin classdoc

Check params required for managing network connectivity.

@see <package>Manager::NetworkManager</package>

=end classdoc
=cut

sub checkNetworkManagerParams {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => []); # was: 'subnets'
}


=pod
=begin classdoc

Remove the network manager params entry from a hash ref.

@see <package>Manager::NetworkManager</package>

=end classdoc
=cut

sub releaseNetworkManagerParams {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "params" ]);

    delete $args{params}->{network_tenant};
    delete $args{params}->{subnets};
}

=pod
=begin classdoc

Internal method to give the hypervisor description
(used in more than one place). Helps finding the hypervisor.

=end classdoc
=cut

sub _getHypervisorDescription {
    my ($self) = @_;
    return 'AWS infrastructure for account '.$self->id; 
}

=pod
=begin classdoc

Get the (only) hypervisor for this Component.
Throws an exception if the hypervisor has not been registered yet.

@return An Entity::Host instance.

=end classdoc
=cut

sub getTheHypervisor {
    my ($self) = @_;
    return Entity::Host->find(hash => { host_serial_number => $self->_getHypervisorDescription });
}




=pod
=begin classdoc

Check for virtual machine placement, and create the virtual host instance.

@param type (String) The AWS Instance Type.

@see <package>Manager::HostManager</package>

=end classdoc
=cut

sub getFreeHost {
    my ($self, %args) = @_;

    General::checkParams(args => \%args,
                         required => [ 'type' ]); # subnets ?

    try {
        return $self->createAwsVirtualHost(
            aws_instance_type => $args{type},
            ifaces            => 1, # scalar(@{ [ $args{subnets} ] }),
            instance_id       => 'to be determined'
        );
    }
    catch ($err) {
        # We can't create virtual host for some reasons (e.g can't meet constraints)
        throw Kanopya::Exception::Internal(
            error => "Virtual machine manager <" . $self->label . "> has not capabilities " .
                     "to host this VM of type with type <$args{type}>:\n" . $err
        );
    }
}


#=pod
#=begin classdoc
#
#Return the boot policies for the host ruled by this host manager
#
#@see <package>Manager::HostManager</package>
#
#=end classdoc
#=cut
#
#sub getBootPolicies {
#    my $self = shift;
#
#    return (Manager::HostManager->BOOT_POLICIES->{virtual_disk});
#}
#
#
=pod
=begin classdoc

Create and start a virtual machine from the given parameters.

@see <package>Manager::HostManager</package>

@param Host (Entity::Host::VirtualMachine) The host to start.
@param type (String) The Instance Type name (e.g. 't2.micro').

=end classdoc
=cut

sub startHost {
    my ($self, %args) = @_;

    General::checkParams(args  => \%args,
                         # required => [ 'host', 'flavor', 'hypervisor' ],
                         required => [ 'host', 'type' ],
                         optional => {hypervisor => undef});

    my $host = $args{host};
    my $node = $host->node;

    # We need the AWS Image ID, we get it through the systemimage description. 
    my $instance = $self->_ec2->createInstance(
        ImageId      => $self->_removeAwsPrefix( $node->systemimage->systemimage_desc ),
        InstanceType => $args{type}
    );
    my $vm_info = $instance->arrayref->[0];
    
    # Only NOW we know some data: MAC address, instance ID...
    my $serial_number = $self->_addAwsPrefix($vm_info->{instance_id});
    $host->update(host_serial_number => $serial_number);
    $host->getIfaces->[0]->update(iface_mac_addr   => $vm_info->{mac_addr});
    $node->update(node_hostname => $serial_number);
    
    $self->setNodeState(node => $node, vm_info => $vm_info);
    
    return;
}


=pod
=begin classdoc

Terminate the VM.

@see <package>Manager::HostManager</package>

=end classdoc
=cut

sub stopHost {
    my ($self, %args) = @_;
    General::checkParams(args  => \%args, required => [ "host" ]);
    
    my $instance_id = $self->_removeAwsPrefix($args{host}->host_serial_number);
    my $errors = $self->_ec2->terminateInstance(InstanceId => [$instance_id]);

    if (@$errors > 0) {
        $log->warn('Errors during AWS node termination: '.Data::Dumper->Dump($errors));
    }
}


#=pod
#=begin classdoc
#
#Sclar cpu or ram of the virtual machine by calling the nova api.
#
#@param host_id Host instance id to scale
#@param scalein_value Wanted value
#@param scalein_type Selectsthe metric to scale in either 'ram' or 'cpu'
#
#@see <package>Manager::HostManager::VirtualMachineManager</package>
#
#=end classdoc
#=cut
#
#sub scaleHost {
#    my ($self,%args) = @_;
#
#    General::checkParams(args => \%args, required => [ 'host_id', 'scalein_value', 'scalein_type' ]);
#
#    throw Kanopya::Exception::NotImplemented();
#}
#
#
#=pod
#=begin classdoc
#
#Migrate a host to the destination hypervisor by calling the nova api.
#
#@see <package>Manager::HostManager::VirtualMachineManager</package>
#
#=end classdoc
#=cut
#
#sub migrateHost {
#    my ($self, %args) = @_;
#    General::checkParams(args => \%args, required => [ 'host', 'hypervisor' ]);
#
#    OpenStack::Server->migrate(
#        api => $self->_api,
#        id => $args{host}->openstack_vm_uuid,
#        hypervisor_hostname => $args{hypervisor}->node->node_hostname,
#    );
#
#    return;
#}
#
#
#=pod
#=begin classdoc
#
#Promote host into OpenstackVm and set its hypervisor id
#
#@return the promoted host
#
#@see <package>Manager::HostManager::VirtualMachineManager</package>
#
#=end classdoc
#=cut
#
#sub promoteVm {
#    my ($self, %args) = @_;
#
#    General::checkParams(args     => \%args,
#                         required => [ 'host', 'vm_uuid' ],
#                         optional => { 'hypervisor_id' => undef });
#
#     $args{host} = Entity::Host::VirtualMachine::OpenstackVm->promote(
#                       promoted           => $args{host},
#                       nova_controller_id => $self->id,
#                       openstack_vm_uuid  => $args{vm_uuid},
#                   );
#
#    $args{host}->hypervisor_id($args{hypervisor_id});
#    return $args{host};
#}
#
#
#=pod
#=begin classdoc
#
#Get the detail of a vm
#
#@params host vm
#
#=end classdoc
#=cut
#
#sub getVMDetails {
#    my ($self, %args) = @_;
#    General::checkParams(args => \%args, required => [ 'host' ]);
#
#    my $details = OpenStack::Server->detail(
#                      api => $self->_api,
#                      id => $args{host}->openstack_vm_uuid,
#                      flavor_detail => 1,
#                  );
#
#    if (defined $details->{itemNotFound}) {
#        throw Kanopya::Exception(error => $details->{itemNotFound});
#    }
#
#    return {
#        hypervisor => $details->{server}->{'OS-EXT-SRV-ATTR:host'},
#        state => $details->{server}->{status},
#        ram => $details->{server}->{flavor}->{ram} * 1024 * 1024, #MB to B
#        cpu => $details->{server}->{flavor}->{vcpus},
#    };
#}
#
#
#=pod
#
#=begin classdoc
#
#Retrieve the state of a given VM
#
#@return state
#
#=end classdoc
#
#=cut
#
#sub getVMState {
#    my ($self, %args) = @_;
#    General::checkParams(args => \%args, required => [ 'host' ]);
#
#    try {
#        my $details =  $self->getVMDetails(%args);
#
#        my $state_map = {
#            'MIGRATING' => 'migr',
#            'BUILD'     => 'pend',
#            'REBUILD'   => 'pend',
#            'ACTIVE'    => 'runn',
#            'ERROR'     => 'fail',
#            'SHUTOFF'   => 'shut'
#        };
#
#        return {
#            state      => $state_map->{$details->{state}} || 'fail',
#            hypervisor => $details->{hypervisor},
#        };
#    }
#    catch ($err) {
#        $log->warn($err);
#    }
#}

=pod
=begin classdoc

Dummy operation in AWS, because Hosts get created directly from the master image.
There is no separate step for creating a system volume.

@see <package>Manager::StorageManager</package>

@param masterimage (Entity::Masterimage) The master image for this system image.
@param systemimage_name (String)

=end classdoc
=cut

sub createSystemImage {
    my ($self, %args) = @_;
    General::checkParams(args     => \%args,
                         required => [ 'masterimage', 'systemimage_name' ]);
    
    # If a systemimage_desc is given, it is not used, because _we_ use that field
    # to store the connection to the masterimage.
    # If it is important to let the caller set this field, we'd need to use some
    # other (subclass) field, a ParamPreset, or something else.
    
    return Entity::Systemimage->new(
        storage_manager_id => $self->id,
        # names must be unique, descriptions not
        systemimage_name => $args{systemimage_name},
        systemimage_desc => $self->_addAwsPrefix($args{masterimage}->masterimage_file)
    );
}

# RHEL-7.0_GA_HVM-x86_64-3-Hourly2_1413821822


=pod
=begin classdoc

Remove a system image from the storage system.
In AWS, root partitions are linked to the instance. Terminate the instance, and you'll drop the images.
(Or we keep the image next to it. This is subject to discussion.)

@see <package>Manager::StorageManager</package>

@param systemimage (Entity::Systemimage)

=end classdoc
=cut

sub removeSystemImage {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ "systemimage" ]);
    
    $args{systemimage}->delete;
}


=pod
=begin classdoc

Give this node access to the systemimage.

@see <package>Manager::StorageManager</package>

=end classdoc
=cut

# NOTE MERGE: NO-OP in AWS - as in OpenStack.
sub attachSystemImage {
    my ($self, %args) = @_;
    $log->debug('No system image to attach');
    return;
}


#=pod
#=begin classdoc
#
#@return the name of the type of storage provided by this storage manager.
#
#@see <package>Manager::StorageManager</package>
#
#=end classdoc
#=cut
#
#sub storageType {
#    return "OpenStack Cinder";
#}


=pod
=begin classdoc

Do the required configuration/actions to provides the boot mechanism for the node.

@see <package>Manager::BootManager</package>

=end classdoc
=cut

sub configureBoot {
    my ($self, %args) = @_;
    $log->debug('No boot configuration');
    return;
}


=pod
=begin classdoc

Workaround for the native HCM boot manager that requires the configuration
of the boot made in 2 steps.

Apply the boot configuration set at configureBoot

@see <package>Manager::BootManager</package>

=end classdoc
=cut

# NOTE MERGE: same as in OpenStack
sub applyBootConfiguration {
    my ($self, %args) = @_;
    $log->debug('No boot configuration to apply');
    return;
}


=pod
=begin classdoc

Do the required configuration/actions to provides the proper network connectivity
to the node from the network manager params.

@see <package>Manager::NetworkManager</package>

=end classdoc
=cut

sub configureNetworkInterfaces {
    my ($self, %args) = @_;
    
    # For AWS, we leave the network aside for the moment.
#    General::checkParams(args => \%args, required => [ 'subnets', 'node' ]);
    
#    $log->debug("network configuration: ".Data::Dumper->Dump([ \%args ]));
#
#    my $pp = $self->param_preset->load;
#    my @ifaces = $args{node}->host->getIfaces;
#    my $port_macs = {};
#    for my $subnet (@{ $args{subnets} }) {
#        (my $subnet_addr = $subnet) =~ s/ \(.*\)$//g;
#        (my $network_name = $subnet) =~ s/^.* \(//g;
#        $network_name =~ s/\)$//g;
#
#        my $subnet_id;
#        my $network_id = $pp->{networks_name_id}->{$network_name};
#        try {
#            my @uuids = grep { $pp->{subnets}->{$_}->{cidr} eq $subnet_addr }
#                            @{ $pp->{networks}->{$network_id}->{subnets} };
#            $subnet_id = pop(@uuids);
#        }
#        catch ($err) {
#            throw Kanopya::Exception::Internal::Inconsistency(
#                      error => "Unable to retrieve network and subnet id for $subnet:$err"
#                  );
#        }
#
#        $log->info("Found network $network_id and subnet $subnet_id for $subnet.");
#        my $port = OpenStack::Port->create(api        => $self->_api,
#                                           network_id => $network_id,
#                                           subnet_id  =>  $subnet_id);
#
#        $port_macs->{$port->{port}->{mac_address}} = $port->{port}->{id};
#
#        # Assign the resulting ip the the next iface
#        my $iface = shift(@ifaces);
#        $log->info('Assign iface ' . $iface->iface_name . ' with ip <' .
#                   $port->{port}->{fixed_ips}->[0]->{ip_address} . '> and mac <' .
#                   $port->{port}->{mac_address} . '>');
#
#        $iface->assignIp(ip_addr => $port->{port}->{fixed_ips}->[0]->{ip_address});
#        $iface->iface_mac_addr($port->{port}->{mac_address});
#
#        # If the node admin ip not set, use the first one
#        if (! defined $args{node}->admin_ip_addr) {
#            $args{node}->admin_ip_addr($port->{port}->{fixed_ips}->[0]->{ip_address});
#        }
#    }
#
#    # TODO store information elsewhere
#    $self->param_preset->update(params => { port_macs => $port_macs });

    return;
}

=pod
=begin classdoc

Remove the network configurations.

@see <package>Manager::NetworkManager</package>

=end classdoc
=cut

sub unconfigureNetworkInterface {
    my ($self, %args) = @_;
#    my @mac_addresses = map {$_->reload->iface_mac_addr} $args{node}->host->getIfaces;
#
#    my $params = $self->param_preset->load;
#
#    for my $addr (@mac_addresses) {
#        if (! defined $params->{port_macs}->{$addr}) {
#            $log->warn('Cannot find port_uuid and delete OpenStack Port. '
#                       . ' this can happened when the port creation and the '
#                       . ' exception occurs during the same transaction');
#        }
#        else {
#            try {
#                OpenStack::Port->delete(
#                    api => $self->_api,
#                    id => $params->{port_macs}->{$addr}
#                );
#            }
#            catch($err) {
#                $log->warn('Error when deleting port:' . $err);
#            }
#            delete $params->{port_macs}->{$addr};
#        }
#    }
#    $self->param_preset->update(params => $params, override => 1);
    return;
}

=pod
=begin classdoc


Query AWS to register a "virtual" hypervisor, existing virtual machines
and all available options.

=end classdoc
=cut

# NOTE MERGE: code is the same as in OpenStack.pm
sub synchronize {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { 'workflow' => undef });

    return $self->executor_component->run(
               name   => 'Synchronize',
               workflow => delete $args{workflow},
               params => {
                   context => {
                       entity => $self
                   }
               }
           );
}


=pod
=begin classdoc

Stop a host.

=end classdoc
=cut

# TODO: is it not useless to call this right before calling stopHost ?

sub halt {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'host' ]);
    my $instance_id = $self->_removeAwsPrefix($args{host}->host_serial_number);
    my $errors = $self->_ec2->stopInstance(InstanceId => [$instance_id]);
    
    if (@$errors > 0) {
        $log->warn('Errors during AWS node halt: '.Data::Dumper->Dump($errors));
    }
    
#    try {
#        OpenStack::Server->stop(api => $self->_api, id => $args{host}->openstack_vm_uuid);
#    }
#    catch($err) {
#        $log->warn('Error during openstack node halt ' . $err);
#    }
}

=pod
=begin classdoc

Release a host, delete the Entity::Host object.

=end classdoc
=cut


sub releaseHost {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'host' ]);

    return $args{host}->delete();
}

=pod
=begin classdoc

Get all the VMs of an hypervisor. Ask directly AWS.
Our caller, EVirtualMachineManager::checkHypervisorVMPlacementIntegrity(),
will compare the results with what is stored in the DB.

Our caller expects a hashref with two keys:
* "vms" with all VMs (Host instances) known by AWS;
* "unk_vm_uuids" with the VMs known by AWS but unknown by the database.

=end classdoc
=cut

sub getHypervisorVMs {
    my ($self, %args) = @_;
    # General::checkParams(args => \%args, required => []);
    
    my $infra_vms = $self->_ec2->getInstances();
    my @infra_vm_sn_list = map { $self->_addAwsPrefix($_->{instance_id}) } @{$infra_vms->arrayref};

    # Let's try to do this in one single DB request.
    my @hosts = Entity::Host::VirtualMachine->search(hash => {
       host_serial_number => \@infra_vm_sn_list 
    });
     
    my %sn_found = map { $_ => 0 } @infra_vm_sn_list; 
    foreach my $host (@hosts) {
        $sn_found{$host->host_serial_number} = 1;
    }
    my @unk_vm_uuids = grep { $sn_found{$_} == 0 } keys(%sn_found);
    
    my $result = {
        vms          => \@hosts,
        unk_vm_uuids => \@unk_vm_uuids
    };
    $log->debug("VHH DEBUG: result is: ".Data::Dumper->Dump([ $result ]));
    return $result;
}


=pod
=begin classdoc

There is only one hypervisor, but we still let the Capacity Manager
do its work. This method is adapted to deal with AWS instance types.

(HostManager interface)

=end classdoc
=cut

sub selectHypervisor {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'type' ]);

    my $aws_type = AwsInstanceType->getType(name => $args{type});
    
    my $cm = CapacityManagement->new(cloud_manager => $self);
    return $cm->getHypervisorIdForVM(resources => {
        ram => $aws_type->ram, 
        cpu => $aws_type->cpu
    });
}

=pod
=begin classdoc

Actions to do after the successful start of a node.

=end classdoc
=cut


sub postStart {
    # my ($self, %args) = @_;
    # General::checkParams(args => \%args, required => [ 'host' ]);
    
    # Nothing left to do for AWS! The Host already knows its "hypervisor".
}

=pod
=begin classdoc

Increase the number of current consumers of the manager.
(HostManager, StorageManager)

=end classdoc
=cut

# NOTE MERGE: identical with the code in OpenStack.pm
sub increaseConsumers {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'operation' ]);

    my @states = $self->entity_states;

    for my $state (@states) {
        if ($state->consumer_id eq $args{operation}->workflow_id) {
            next;
        }
        throw Kanopya::Exception::Execution::InvalidState(
                  error => "Entity state <" . $state->state
                           . "> already set by consumer <"
                           . $state->consumer->label . ">"
              );
    }

    $self->setConsumerState(
        state => $args{operation}->operationtype->operationtype_name,
        consumer => $args{operation}->workflow,
    );
}

=pod
=begin classdoc

Decrease the number of current consumers of the manager.
(HostManager, StorageManager)

=end classdoc
=cut

# NOTE MERGE: identical with the code in OpenStack.pm
sub decreaseConsumers {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'operation' ]);
    $self->removeState(consumer => $args{operation}->workflow);
}


#=pod
#=begin classdoc
#
#Remove related master images
#
#=end classdoc
#=cut
#
#sub removeMasterimages {
#    my ($self, %args) = @_;
#    my $images = $self->param_preset->load->{images};
#    for my $image (values %$images) {
#        try {
#            Entity::Masterimage::GlanceMasterimage->find(hash => {
#                masterimage_name => $image->{name},
#                masterimage_file => $image->{file},
#            })->delete();
#        }
#        catch (Kanopya::Exception::Internal::NotFound $err) {
#            $log->warn('Systeimage <' . $image->{name} . '> seems to have been already deleted');
#        }
#        catch ($err) {
#            $err->rethrow;
#        }
#    }
#}
#
#=pod
#=begin classdoc
#
#Ovveride the vmms relation to raise an execption as the OpenStack iaas do not manage the hypervisors.
#
#=end classdoc
#=cut
#
#sub vmms {
#    my ($self, %args) = @_;
#
#    throw Kanopya::Exception::Internal(error => "Hypervisors not managerd by iaas " . $self->label);
#}
#
#
#sub _api {
#    my ($self, %args) = @_;
#
#    if (defined $self->{_api}) {
#        return $self->{_api};
#    }
#
#    General::checkParams(args => \%args,
#                         optional => { api_username => $self->api_username || 'admin',
#                                       api_password => $self->api_password || 'keystone',
#                                       keystone_url => $self->keystone_url || 'localhost',
#                                       tenant_name  => $self->tenant_name  || 'openstack' } );
#
#    $self->{_api} = OpenStack::API->new(user         => $args{api_username},
#                                        password     => $args{api_password},
#                                        tenant_name  => $args{tenant_name},
#                                        keystone_url => $args{keystone_url});
#
#    return $self->{_api}
#}


=pod
=begin classdoc

A variant of VirtualMachineManager::createVirtualHost that is more appropriated for us.

@param aws_instance_type (AwsInstanceType or String) The instance type for which we need a "Host" instance.
@param instance_id (String) Used for construction of the host's serial number.
@param ifaces (Integer) Number of interfaces.

=end classdoc
=cut

sub createAwsVirtualHost {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'aws_instance_type', 'instance_id' ],
                         optional => { 'hypervisor_id' => undef, 'mac_address' => undef,
                                       'ifaces' => 1 });

    # Only make these calls if necessary
    $args{hypervisor_id} = $self->getTheHypervisor->id unless defined $args{hypervisor_id};
    $args{mac_address}   = $self->generateMacAddress() unless defined $args{mac_address};

    my $aws_it = $args{aws_instance_type};
    if (ref($aws_it) eq '') {
        $aws_it = AwsInstanceType->getType(name => $aws_it);
    }

    # Use the first kernel found...
    my $kernel = Entity::Kernel->find(hash => {});

    my $vm = Entity::Host::VirtualMachine->new(
                 host_manager_id    => $self->id,
                 hypervisor_id      => $args{hypervisor_id},
                 host_serial_number => $self->_addAwsPrefix($args{instance_id}),
                 kernel_id          => $kernel->id,
                 host_ram           => $aws_it->ram, 
                 host_core          => $aws_it->cpu,
                 active             => 1,
             );

    foreach (0 .. $args{ifaces}-1) {
        $vm->addIface(
            iface_name     => 'eth' . $_,
            iface_mac_addr => $args{mac_address},
            iface_pxe      => $_ == 0 ? 1 : 0,
        );
    }

    return $vm;
}


=pod
=begin classdoc

Tiny helper function to translate from AWS Instance IDs to HCM Host Serial Numbers.
Class or instance method.

@param instance_id (String, direct parameter) The AWS Instance ID
@return A "serial number" for a HCM Host instance. 

=end classdoc
=cut

sub _addAwsPrefix {
    my ($clob, $str) = @_;
    return "aws_$str";
}

=pod
=begin classdoc

Tiny helper function to translate from HCM Host Serial Numbers to AWS Instance IDs.
Class or instance method. Throws an exception if the Serial Number cannot correspond
to an AWS Instance ID.

@param serial_number (String, direct parameter) The Host "Serial number"
@return The AWS Instance ID. 

=end classdoc
=cut

sub _removeAwsPrefix {
    my ($clob, $serial_number) = @_;
    if ($serial_number =~ m/^aws_(.*)$/) {
        return $1;
    } else {
        throw Kanopya::Exception::Internal::WrongValue(
            error => "The serial number '$serial_number' does not contain a valid AWS Instance ID"
        )
    }
}




=pod
=begin classdoc

Synchronize the retrieved AWS infrastructure with HCM.

@param infra (Hashref) The infrastructure. See AWS::EC2->getInfrastructure() for the structure. 

=end classdoc
=cut

sub _load {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'infra' ]);

#    my $tenants_name_id = {};
#    my $tenants = {};
#    for my $tenant (@{$args{infra}->{tenants}}) {
#        $tenants_name_id->{$tenant->{name}} = $tenant->{id};
#        $tenants->{$tenant->{id}} = $tenant;
#        $tenants->{$tenant->{id}}->{networks} = [];
#    }
#
#    my $zones = {};
#    for my $zone (@{$args{infra}->{availability_zones}}) {
#        # A zone has no id
#        $zones->{$zone->{zoneName}} = $zone;
#    }
#
#    my $flavors = {};
#    for my $flavor (@{$args{infra}->{flavors}}) {
#        $flavors->{$flavor->{id}} = $flavor;
#    }
#
#    my $subnets = {};
#    for my $subnet (@{$args{infra}->{subnets}}) {
#        $subnets->{$subnet->{id}} = $subnet;
#    }
#
#    my $volume_types = {};
#    for my $volume_type (@{ $args{infra}->{volume_types} }) {
#        $volume_types->{delete $volume_type->{id}} = $volume_type;
#    }

#    my $images = {};
#    for my $image (@{$args{infra}->{images}}) {
#        $images->{$image->{id}} = $image;
#    }

#    my $networks_name_id = {};
#    my $networks = {};
#    for my $network (@{$args{infra}->{networks}}) {
#        push @{$tenants->{$network->{tenant_id}}->{networks}}, $network->{id};
#        $networks_name_id->{$network->{name}} = $network->{id};
#        $networks->{$network->{id}} = $network
#    }
#
#    my $pp = $self->param_preset;
#    $pp->update(
#        params => {
#            tenants => $tenants,
#            networks => $networks,
#            subnets => $subnets,
#            volume_types => $volume_types,
#            flavors => $flavors,
#            zones => $zones,
#            images => $images,
#            # TODO Remove following and find better method
#            networks_name_id => $networks_name_id,
#            tenants_name_id => $tenants_name_id,
#        },
#        override => 1,
#    );
#
    # Manage images
    my $cluster_type_id = ClassType::ServiceProviderType::ClusterType->find(
                              service_provider_name => 'Cluster'
                          )->id;

    # TODO: Master images (and system images) should be managed by a dedicated component 
    # with its dedicated tables. With more and more different external infrastructures,
    # it makes no sense any more to throw them all together.
    # But this will need quite a bit of refactoring.
    foreach my $image_info (@{$args{infra}->{images}}) {
        Entity::Masterimage::AwsMasterimage->createOrUpdate(
            find => {
                masterimage_file => $image_info->{image_id}        
            },
            update => {
                masterimage_name => $image_info->{name},
                masterimage_size => $image_info->{size},
                masterimage_desc => $image_info->{desc},
                masterimage_cluster_type_id => $cluster_type_id
            }
        );
    }
    
    # Manage hypervisors
    # TODO: this must correspond to our "quota", defined by AWS or defined by the HCM admin!
    my $hypervisor = Entity::Host->createOrUpdate(
        find => {
            host_serial_number => $self->_getHypervisorDescription
        },
        update => {
            active => 1,
            host_ram => 100 * 1024**3,  # enough !
            host_core => 3, # not more than three simultaneous instances on the Free Tier
        }
    );
    my $hypervisor_id = $hypervisor->id;
    
    # NOTE MERGE: from here on, large blocks are identical with the code in OpenStack.pm
    
    $hypervisor->setState(state => 'up');
    
    if (! $hypervisor->isa("Entity::Host::Hypervisor")) {
        $self->addHypervisor(host => $hypervisor);
    }
       
    # Create the corresponding node
    Entity::Node->createOrUpdate(
        find => {
            host_id => $hypervisor_id
        },
        update => {
            node_hostname => $self->_addAwsPrefix($self->id),
            node_state    => 'in:' . time(),
            node_number   => 1
        },
        do_not_update_existing_instance => 1
    );

    my $vm_count = 1;
    for my $vm_info (@{$args{infra}->{instances}->arrayref}) {
        $vm_count++;
        
        # my $network_info = $vm_info->{addresses};
        my $serial_number = $self->_addAwsPrefix($vm_info->{instance_id}); 
        my $aws_type      = AwsInstanceType->getType(name => $vm_info->{type});
        my $vm;
        my %hyp_hash = (
            hypervisor_id => $hypervisor_id        
        );
        try {
            $vm = Entity::Host::VirtualMachine->find(hash => {
                %hyp_hash,
                serial_number     => $serial_number
            });

        } catch (Kanopya::Exception::Internal::NotFound $err) {
            $vm = $self->createAwsVirtualHost(
                %hyp_hash,
                instance_id       => $vm_info->{instance_id},
                aws_instance_type => $vm_info->{type},
                ifaces            => 1, # scalar (keys %$network_info),
                mac_address       => $vm_info->{mac_addr}
            );
        }
                
        # Create the corresponding node if not exist
        my $node = Entity::Node->createOrUpdate(
            find => {
                host_id => $vm->id
            },
            update => {
                node_hostname  => $serial_number,
                node_number    => $vm_count,
                systemimage_id => undef, # TODO ?
                admin_ip_addr  => $vm_info->{ip}  
            }
        );

        $self->setNodeState(node => $node, vm_info => $vm_info);

#            my @ifaces = $vm->ifaces;
#            while(my ($name, $ip_infos) = each(%$network_info)) {
#
#                # TODO Manage floating ips
#
#                my $ip_info;
#                # '=' is ok, we assign first and then we test
#                while(($ip_info = (pop @$ip_infos)) && ($ip_info->{'OS-EXT-IPS:type'} ne 'fixed')) {}
#
#                if (defined $ip_info) {
#                    my $iface = (pop @ifaces);
#                    $iface->iface_mac_addr($ip_info->{'OS-EXT-IPS-MAC:mac_addr'});
#                    Ip->new(
#                        ip_addr  => $ip_info->{addr},
#                        iface_id => $iface->id,
#                    );
#                    $node->admin_ip_addr($ip_info->{addr});
#                }
#            }
#        }
    }
}

1;

