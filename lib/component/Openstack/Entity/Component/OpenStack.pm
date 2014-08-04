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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod
=begin classdoc

The OpenStack component is designed to manage an exiting deployment of OpenStack apis.
This component is able to synchronise the existing infrastructure to the HCM api, and load
the available parameters/option for each OpenStack services.

It implements the 3 HCM drivers interfaces VirtualMachineManager, DiskManager, ExportManager.

To instanciate this component in way to manage an existing OpenStack installation,

=end classdoc
=cut

package Entity::Component::OpenStack;
use parent Entity::Component;
use parent Manager::HostManager::VirtualMachineManager;
use parent Manager::StorageManager;
use parent Manager::BootManager;

use strict;
use warnings;

use Kanopya::Exceptions;

use TryCatch;
use Log::Log4perl "get_logger";
my $log = get_logger("");


use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }


=pod
=begin classdoc

@return the network configuration used to check the availability of the openstack apis.

=end classdoc
=cut

sub getNetConf {
    my $self = shift;

    my $conf = {
        novncproxy => {
            port => 6080,
            protocols => ['tcp']
        },
        ec2 => {
            port => 8773,
            protocols => ['tcp']
        },
        compute_api => {
            port => 8774,
            protocols => ['tcp']
        },
        metadata_api => {
            port => 8775,
            protocols => ['tcp']
        },
        volume_api => {
            port => 8776,
            protocols => ['tcp']
        },
        glance_registry => {
            port => 9191,
            protocols => ['tcp']
        },
        image_api => {
            port => 9292,
            protocols => ['tcp']
        },
        keystone_service => {
            port => 5000,
            protocols => ['tcp']
        },
        keystone_admin => {
            port => 35357,
            protocols => ['tcp']
        },
        neutron => {
            port => 9696,
            protocols => ['tcp']
        }
    };

    return $conf;
}


=pod
=begin classdoc

@return the manager params definition.

=end classdoc
=cut

sub getManagerParamsDef {
    my ($self, %args) = @_;

    return {
        %{ $self->SUPER::getManagerParamsDef },
        flavor => {
            label        => 'Flavor',
            # TODO: Use type enum, and return flavors contained in
            # the extra configuration filled at sync
            type         => 'string',
            pattern      => '^.*$',
            is_mandatory => 1
        },
        cinder_backend => {
            label        => 'Storage backend',
            type         => 'enum',
            is_mandatory => 1,
            # TODO:  Get the enum options from the available synchronized backend
            options      => [ 'NFS', 'iSCSI', 'RADOS' ]
        },
        repository   => {
            is_mandatory => 1,
            label        => 'Repository',
            type         => 'enum',
        },
    };
}


=pod
=begin classdoc

Return the parameters definition available for the VirtualMachineManager api.

@see <package>Manager::HostManager</package>

=end classdoc
=cut

sub getHostManagerParams {
    my $self = shift;
    my %args = @_;

    return {
        flavor => $self->getManagerParamsDef->{flavor},
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

    General::checkParams(args => \%args, required => [ 'flavor' ]);
}


=pod
=begin classdoc

Return the parameters definition available for the DiskManager api.

@see <package>Manager::StorageManager</package>

=end classdoc
=cut

sub getStorageManagerParams {
    my ($self, %args) = @_;

    return { cinder_backend => $self->getManagerParamsDef->{cinder_backend} };
}


=pod
=begin classdoc

Check parameters that will be given to the DiskManager api methods.

@see <package>Manager::StorageManager</package>

=end classdoc
=cut

sub checkStorageManagerParams {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'cinder_backend' ]);
}


=pod
=begin classdoc

Return the boot policies for the host ruled by this host manager

@see <package>Manager::HostManager</package>

=end classdoc
=cut

sub getBootPolicies {
    my $self = shift;

    return (Manager::HostManager->BOOT_POLICIES->{virtual_disk});
}


=pod
=begin classdoc

Create and start a virtual machine from the given parameters by calling the nova api.

@see <package>Manager::HostManager</package>

=end classdoc
=cut

sub startHost {
    my ($self, %args) = @_;

    General::checkParams(args  => \%args, required => [ "host" ]);

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

Stop the virtual machine by calling the nova api.

@see <package>Manager::HostManager</package>

=end classdoc
=cut

sub stopHost {
    my ($self, %args) = @_;

    General::checkParams(args  => \%args, required => [ "host" ]);

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

Sclar cpu or ram of the virtual machine by calling the nova api.

@param host_id Host instance id to scale
@param scalein_value Wanted value
@param scalein_type Selectsthe metric to scale in either 'ram' or 'cpu'

@see <package>Manager::HostManager::VirtualMachineManager</package>

=end classdoc
=cut

sub scaleHost {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'host_id', 'scalein_value', 'scalein_type' ]);

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

Migrate a host to the destination hypervisor by calling the nova api.

@see <package>Manager::HostManager::VirtualMachineManager</package>

=end classdoc
=cut

sub migrate {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host_id', 'hypervisor_id' ]);

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

Return a list of hypervisors under the rule of this instance of manager

@return opnestack_hypervisors

@see <package>Manager::HostManager::VirtualMachineManager</package>

=end classdoc
=cut

sub hypervisors {
    my $self = shift;

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

Promote host into OpenstackVm and set its hypervisor id

@return the promoted host

@see <package>Manager::HostManager::VirtualMachineManager</package>

=end classdoc
=cut

sub promoteVm {
    my ($self, %args) = @_;

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

Create a system image for a node.
Should fill the systemimage with the masterimage contents if defined.

@see <package>Manager::StorageManager</package>

=end classdoc
=cut

sub createSystemImage {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ "systemimage_name" ],
                         optional => { "systemimage_desc" => "",
                                       "masterimage"      => undef });

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

Remove a system image from the storage system.

@see <package>Manager::StorageManager</package>

=end classdoc
=cut

sub removeSystemImage {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "systemimage" ]);

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

Do required struff for giving access for the node to the systemimage.

@see <package>Manager::StorageManager</package>

=end classdoc
=cut

sub attachSystemImage {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "node", "systemimage" ]);

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

@return the name of the type of storage provided by this storage manager.

@see <package>Manager::StorageManager</package>

=end classdoc
=cut

sub storageType {
    return "OpenStack Cinder";
}


=pod
=begin classdoc

Do the required configuration/actions to provides the boot mechanism for the node.

=end classdoc
=cut

sub configureBoot {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ "node", "systemimage", "boot_policy" ],
                         optional => { "remove" => 0 });

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

Workaround for the native HCM boot manager that requires the configuration
of the boot made in 2 steps.

Apply the boot configuration set at configureBoot

=end classdoc
=cut

sub applyBootConfiguration {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ "node", "systemimage", "boot_policy" ],
                         optional => { "remove" => 0 });

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

Querry the openstack API to register exsting hypervisors, virtaul machines
and all options available in the existing OpenStack.

=end classdoc
=cut

sub synchronize {
    my ($self, @args) = @_;

    throw Kanopya::Exception::NotImplemented();
}

1;
