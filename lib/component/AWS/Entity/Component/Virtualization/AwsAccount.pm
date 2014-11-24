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
use CapacityManager::HCMCapacityManager;
use ClassType::ServiceProviderType::ClusterType;
use Entity::Masterimage::AwsMasterimage;
use Kanopya::Database;
use Kanopya::Exceptions;

use Data::Dumper;
use Log::Log4perl "get_logger";
my $log = get_logger("");
use TryCatch;

########## ENTITY::COMPONENT::VIRTUALIZATION METHODS ##########################

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
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1
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

    Kanopya::Database::beginTransaction();

    my $self = $class->SUPER::new(%args); # among the args: the executor_component_id
    foreach my $key (@$fields, 'region') {
        $self->{key} = $args{key};
    }
    
    # Get available regions: this not only checks whether we are allowed in the given region,
    # it also tests our access data !
    my $available_regions;
    try {
        $available_regions = $self->_ec2->getRegions;
    } catch ($ex) {
        Kanopya::Database::rollbackTransaction();
        throw Kanopya::Exception::Internal::WrongValue(
            error => "Unable to connect to AWS, please check your access data."
        );
    }
    
    my %available_regions = map { $_->{name} => 1 } @$available_regions;
    unless (exists $available_regions{$args{region}}) {
        Kanopya::Database::rollbackTransaction();
        throw Kanopya::Exception::Internal::WrongValue(
            error => "The region ".$args{region}." is not available to you."
        );
    } 

    Kanopya::Database::commitTransaction();
    return $self;
}


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

Remove this instance from the database.
Called by a HTTP DELETE.
=end classdoc
=cut

sub remove {
    my ($self, %args) = @_;
    $self->unregister();
    $self->SUPER::remove();
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
    
    return {
               vms          => \@hosts,
               unk_vm_uuids => \@unk_vm_uuids
           };
}


########## MANAGER METHODS, AND METHODS OF SEVERAL INTERFACES #################


=pod
=begin classdoc

@return the manager params definition.

=end classdoc
=cut

sub getManagerParamsDef {
    my ($self, %args) = @_;

    return {
        %{ $self->SUPER::getManagerParamsDef },
        instance_type => {
            label        => 'Instance Type',
            type         => 'enum',
            pattern      => '^.*$',
            is_mandatory => 1
        }
    };
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


######### MANAGER::HOSTMANAGER::VIRTUALMACHINEMANAGER METHODS #################


=pod
=begin classdoc

Return the parameters definition available for the VirtualMachineManager api.

@see <package>Manager::HostManager</package>

=end classdoc
=cut

sub getHostManagerParams {
    my ($self, %args) = @_;

    my $params = $self->getManagerParamsDef;
    my $instance_types = $params->{instance_type};
    $instance_types->{options} = AwsInstanceType->getAllNames;

    return {
        instance_type => $instance_types
    }
}


=pod
=begin classdoc

Check parameters that will be given to the VirtualMachineManager api methods.

@see <package>Manager::HostManager</package>

=end classdoc
=cut

sub checkHostManagerParams {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'instance_type' ]);
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
    General::checkParams(args => \%args, required => [ 'instance_type' ]);

    my $aws_type = AwsInstanceType->getType(name => $args{instance_type});
    
    my $cm = CapacityManager::HCMCapacityManager->new(cloud_manager => $self);
    
    return $cm->selectHypervisor(resources => { 
               ram => $aws_type->ram, 
               cpu => $aws_type->cpu
           });
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
                         required => [ 'instance_type' ]); # subnets ?

    try {
        return $self->createAwsVirtualHost(
            aws_instance_type => $args{instance_type},
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
                         required => [ 'host', 'instance_type' ],
                         optional => {hypervisor => undef});

    my $host = $args{host};
    my $node = $host->node;

    # We need the AWS Image ID, we get it through the systemimage description. 
    my $instance = $self->_ec2->createInstance(
                       ImageId      => $self->_removeAwsPrefix( $node->systemimage->systemimage_desc ),
                       InstanceType => $args{instance_type}
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

Actions to do after the successful start of a node.

=end classdoc
=cut

sub postStart {
    # Nothing left to do for AWS! The Host already knows its "hypervisor".
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


######### MANAGER::STORAGEMANAGER METHODS #####################################


=pod
=begin classdoc

Return the parameters definition available for the DiskManager API.

@see <package>Manager::StorageManager</package>

=end classdoc
=cut

sub getStorageManagerParams {
    my ($self, %args) = @_;

    my $params = {
        masterimage_id => Manager::StorageManager->getManagerParamsDef->{masterimage_id}
    };

    my @masterimages = Entity::Masterimage->search(hash => {
                           storage_manager_id => $self->id 
                       });
    foreach my $masterimage (@masterimages) {
        push @{$params->{masterimage_id}->{options}}, $masterimage->toJSON();
    }

    return $params;
}


=pod
=begin classdoc

Check parameters that will be given to the DiskManager API methods.

@see <package>Manager::StorageManager</package>

=end classdoc
=cut

# NOTE MERGE : nearly the same as OpenStack
sub checkStorageManagerParams {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['masterimage_id']);

    # Workaround: Add a dummy boot_policy to fix missing boot_policy when
    #             when storage manager is not the HCMStorageManager.
    # TODO: Make the param boot_policy required for the HCMDeploymentManager boot manager params
    $args{boot_policy} = 'Boot from AWS image';

    return \%args;
}


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


######### MANAGER::NETWORKMANAGER METHODS #####################################


=pod
=begin classdoc

@return the network manager parameters as an attribute definition.

@see <package>Manager::NetworkManager</package>

=end classdoc
=cut

sub getNetworkManagerParams {
    # All AWS network stuff is still subject to discussion.
    return {};
}


=pod
=begin classdoc

Check params required for managing network connectivity.

@see <package>Manager::NetworkManager</package>

=end classdoc
=cut

sub checkNetworkManagerParams {
    my ($self, %args) = @_;
}


=pod
=begin classdoc

Remove the network manager params entry from a hash ref.

@see <package>Manager::NetworkManager</package>

=end classdoc
=cut

sub releaseNetworkManagerParams {
    my ($self, %args) = @_;
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
    return;
}


######### MANAGER::BOOTMANAGER METHODS ########################################


=pod
=begin classdoc

@return the boot manager parameters as an attribute definition.

@see <package>Manager::BootManager</package>

=end classdoc
=cut

sub getBootManagerParams {
    my ($self, %args) = @_;
    return {};
}


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


########## OWN METHODS ########################################################


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
              );
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

    # Manage images
    my $cluster_type_id = ClassType::ServiceProviderType::ClusterType->find(
                              service_provider_name => 'Cluster'
                          )->id;
    
    foreach my $image_info (@{$args{infra}->{images}}) {
        Entity::Masterimage::AwsMasterimage->createOrUpdate(
            find => {
                masterimage_file => $image_info->{image_id}        
            },
            update => {
                masterimage_name => $image_info->{name},
                masterimage_size => $image_info->{size},
                masterimage_desc => $image_info->{desc},
                masterimage_cluster_type_id => $cluster_type_id,
                storage_manager_id => $self->id
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
    }
}


=pod
=begin classdoc

@return AWS::API instance for this account

=end classdoc
=cut

# We want this already in the constructor, but the object might have been reconstructed
# from the database, without passing by new().
sub _api {
    my ($self) = @_;
    $self->{api} ||= AWS::API->new(aws_account => $self);
    return $self->{api};
}


=pod
=begin classdoc

@return AWS::EC2 instance for this account

=end classdoc
=cut

# We want this already in the constructor, but the object might have been reconstructed
# from the database, without passing by new().
sub _ec2 {
    my ($self) = @_;
    $self->{ec2} ||= AWS::EC2->new(api => $self->_api);
    return $self->{ec2};
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

Forget everything about this infrastructure in the database
(i.e. undo all that _load() has done). 

Only runs when no HCM services depend on the platform any longer.

Does nothing on the remote platform. 

=end classdoc
=cut

sub unregister {
    my ($self, %args) = @_;
    my @spms = $self->service_provider_managers;
    my @spms_left;
    if (@spms) {
        # there might be phantoms from our own tests
        foreach my $spm (@spms) {
            my $sp;
            try {
                $sp = $spm->service_provider;
                push @spms_left, $sp;
            } catch (Kanopya::Exception::Internal::NotFound $ex) {
                $log->info("Deleting empty Service Provider Manager #".$spm->id);
                $spm->remove;
            }
        }
    }
    if (@spms_left) {
        $log->info("still found ".scalar(@spms_left)." non-empty Service Provider Managers:");
        my $spm_left = $spms_left[0];
        my $error = 'Cannot unregister AWS: Still used as "'
                    . $spm_left->manager_category->category_name
                    . '" by cluster "' . $spm_left->service_provider->label . '"';
        throw Kanopya::Exception::Internal(error => $error);
    }

    # No services running any longer? then purge system images from our DB.
    foreach my $systemimage ($self->systemimages) {
        $log->info('Unregistering AWS: deleting left-over systemimage <'.$systemimage->systemimage_name.'>');
        $systemimage->delete;
    }

    for my $vm ($self->hosts) {
        my $node = $vm->node;
        if (defined $node) {
            $log->info('Unregistering AWS: deleting left-over node <'.$node->node_hostname.'>');
            $node->delete;
        }
        $log->info('Unregistering AWS: deleting left-over host <'.$vm->host_desc.'>');
        $vm->delete;
    }

    for my $host ($self->hypervisors) {
        if (defined $host->node) {
            $host->node->delete; # no log message - this one should actually exist
        }
        $host->delete;
    }

    $self->removeMasterimages();
    
    # TODO: why not in OpenStack ? is this too daring ?
    $self->delete;
}


=pod
=begin classdoc

Remove AWS master images

=end classdoc
=cut

sub removeMasterimages {    
    my ($self, %args) = @_;
    my @masterimages = Entity::Masterimage->search(hash => {
                           storage_manager_id => $self->id 
                       });
    foreach my $masterimage (@masterimages) {
        $masterimage->delete();
    }
}

1;

