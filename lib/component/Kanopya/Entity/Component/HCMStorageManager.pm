 # Copyright © 2012-2013 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod
=begin classdoc

HCM native storage manager. Create system images for nodes from disk and export managers.

=end classdoc
=cut

package Entity::Component::HCMStorageManager;
use base "Entity::Component";
use base "Manager::StorageManager";

use strict;
use warnings;

use Entity::Component;
use Kanopya::Exceptions;
use Manager::HostManager;

use TryCatch;
use Hash::Merge;
use Date::Simple (':all');
use Log::Log4perl "get_logger";

my $log = get_logger("");

use constant ATTR_DEF => {
    executor_component_id => {
        label        => 'Workflow manager',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^[0-9\.]*$',
        is_mandatory => 0,
        is_editable  => 0,
    },
    storage_type => {
        is_virtual => 1
    }
};

sub getAttrDef { return ATTR_DEF; }


my $merge = Hash::Merge->new();


=pod
=begin classdoc

@return the storage type description.

@see <package>Manager::StorageManager</package>

=end classdoc
=cut

sub storageType {
    my ($self, %args) = @_;

    return "HCM storage";
}


=pod
=begin classdoc

@return the manager params definition.

=end classdoc
=cut

sub getManagerParamsDef {
    my ($self, %args) = @_;

    my @boot_policies = values(%{ Manager::HostManager->BOOT_POLICIES });
    return {
        # TODO: call super on all Manager supers
        %{ $self->SUPER::getManagerParamsDef },
        boot_policy => {
            label        => 'Boot policy',
            pattern      => '^.*$',
            type         => 'enum',
            is_mandatory => 1,
            options      => \@boot_policies,
        },
        disk_manager_id => {
            label        => 'Disk manager',
            type         => 'relation',
            relation     => 'single',
            pattern      => '^[0-9\.]*$',
            is_mandatory => 1,
            is_editable  => 0,
            order        => 1
        },
        export_manager_id => {
            label        => 'Export manager',
            type         => 'relation',
            relation     => 'single',
            pattern      => '^[0-9\.]*$',
            is_mandatory => 1,
            is_editable  => 0,
            order        => 2
        },
    };
}


=pod
=begin classdoc

@return the managers parameters as an attribute definition. 

@see <package>Manager::StorageManager</package>

=end classdoc
=cut

sub getStorageManagerParams {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { "params" => {} });

    my $paramdef = $self->getManagerParamsDef();
    delete $paramdef->{systemimage_size};
    delete $paramdef->{boot_policy};

    # Fill the attribute definition with availables values for managers
    my $manager_options = {};
    for my $disk_manager (Entity::Component->search(custom => { category => 'DiskManager' })) {
        $manager_options->{$disk_manager->id} = $disk_manager->toJSON;
    }
    my @diskmanageroptions = values %{ $manager_options };
    $paramdef->{disk_manager_id}->{options} = \@diskmanageroptions;

    # Fill the param definition with the disk and export manager ones
    if (defined $args{params}->{disk_manager_id}) {
        my $disk_manager = Entity::Component->get(id => $args{params}->{disk_manager_id});
        $paramdef = $merge->merge($paramdef,
                                  $disk_manager->getDiskManagerParams(params => $args{params}));

        $manager_options = {};
        for my $export_manager (@{ $disk_manager->getExportManagers }) {
            $manager_options->{$export_manager->id} = $export_manager->toJSON;
        }
        my @exportmanageroptions = values %{ $manager_options };
        $paramdef->{export_manager_id}->{options} = \@exportmanageroptions;
    }

    if (defined $args{params}->{export_manager_id}) {
        my $export_manager = Entity::Component->get(id => $args{params}->{export_manager_id});
        $paramdef = $merge->merge($paramdef,
                                  $export_manager->getExportManagerParams(params => $args{params}));
    }

    $paramdef->{masterimage_id} = Manager::StorageManager->getManagerParamsDef->{masterimage_id};

    for my $masterimage ($self->masterimages) {
        push @{$paramdef->{masterimage_id}->{options}}, $masterimage->toJSON();
    }

    return $paramdef;
}


=pod
=begin classdoc

Check params required for creating disks.

@see <package>Manager::StorageManager</package>

=end classdoc
=cut

sub checkStorageManagerParams {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ "disk_manager_id", "systemimage_size" ],
                         optional => { "export_manager_id" => undef });

    my $storage_params = \%args;

    # Instantiate the disk manager and check the params
    my $disk_manager = Entity::Component->get(id => $storage_params->{disk_manager_id});
    $disk_manager->checkDiskManagerParams(%{ $storage_params });

    # Try to instanciate the export manager
    my $export_manager;
    try {
        $export_manager = Entity::Component->get(id => $storage_params->{export_manager_id});
    }
    catch {
        # Export manager undefined
    }

    # If the export manager exists, deduce the boot policy
    if(! ($export_manager and $storage_params->{boot_policy})) {
        if ($export_manager) {
            $storage_params->{boot_policy} = $disk_manager->getBootPolicyFromExportManager(
                                                 export_manager => $export_manager
                                             );
        }
        # Else use the boot policy to deduce the export manager to use
        else {
            # Check the boot policy or the export manager
            if (! defined $storage_params->{boot_policy}) {
                throw Kanopya::Exception::Internal::WrongValue(
                          error => "One must specify either boot_policy or export_manager_id."
                      );
            }

            $export_manager = $disk_manager->getExportManagerFromBootPolicy(
                                  boot_policy => $storage_params->{boot_policy}
                              );

            $storage_params->{export_manager_id} = $export_manager->id;
        }
    }

    # Check the export manager params
    $export_manager->checkExportManagerParams(%{ $storage_params });

    # Get export manager parameter related to si shared value.
    my $readonly_param = $export_manager->getReadOnlyParameter(readonly => 0);
    if ($readonly_param) {
        $storage_params->{$readonly_param->{name}} = $readonly_param->{value};
    }

    return $storage_params;
}


=pod
=begin classdoc

Implemented in the execution entity.

@see <package>Manager::StorageManager</package>

=end classdoc
=cut

sub createSystemImage {
    my ($self, %args) = @_;

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

Implemented in the execution entity.

@see <package>Manager::StorageManager</package>

=end classdoc
=cut

sub removeSystemImage {
    my ($self, %args) = @_;

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

Add the node as client to the system image exports,
build an ISCSI initiator name if required.

@param node the node on which attach the system image
@param systemimage the system image to attach

@see <package>Manager::StorageManager</package>

=end classdoc
=cut

sub attachSystemImage {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'node', 'systemimage' ]);

    # For each container accesses of the system image, add the node as export client
    my $options = "rw";
    my $require_initiator;
    for my $export (map { EEntity->new(data => $_) } $args{systemimage}->container_accesses) {
        EEntity->new(data => $export->export_manager)->addExportClient(
            export  => $export,
            host    => $args{node}->host,
            options => $options
        );

        # If at least one of the access are iscsi based, build an initator name for the host
        if ($export->export_manager->export_type =~ m/ISCSI/) {
            $require_initiator = 1;
        }
    }

    if ($require_initiator && defined $args{node}->host) {
        # Here we compute an iscsi initiator name for the node
        my $date = today();
        my $year = $date->year;
        my $month = length($date->month) == 1 ? '0' . $date->month : $date->month;
        $args{node}->host->host_initiatorname("iqn.$year-$month." . $args{node}->node_hostname . ":" . time);
    }

    # Set the systemimage for the node
    $args{node}->systemimage_id($args{systemimage}->id);
}


=pod
=begin classdoc

Implemented in the execution entity.

@see <package>Manager::StorageManager</package>

=end classdoc
=cut

sub mountSystemImage {
    my ($self, %args) = @_;

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

Implemented in the execution entity.

@see <package>Manager::StorageManager</package>

=end classdoc
=cut

sub umountSystemImage {
    my ($self, %args) = @_;

    throw Kanopya::Exception::NotImplemented();
}

1;
