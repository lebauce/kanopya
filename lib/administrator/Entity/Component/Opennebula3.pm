# Opennebula3.pm - Opennebula3 component
#    Copyright © 2011 Hedera Technology SAS
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
# Created 4 sept 2010

=head1 NAME

<Entity::Component::Opennebula3> <Opennebula3 component concret class>

=head1 VERSION

This documentation refers to <Entity::Component::Opennebula3> version 1.0.0.

=head1 SYNOPSIS

use <Entity::Component::Opennebula3>;

my $component_instance_id = 2; # component instance id

Entity::Component::Opennebula3->get(id=>$component_instance_id);

# Cluster id

my $cluster_id = 3;

# Component id are fixed, please refer to component id table

my $component_id =2

Entity::Component::Opennebula3->new(component_id=>$component_id, cluster_id=>$cluster_id);

=head1 DESCRIPTION

Entity::Component::Opennebula3 is class allowing to instantiate a Opennebula3 component
This Entity is empty but present methods to set configuration.

=head1 METHODS

=cut

package Entity::Component::Opennebula3;
use base "Entity::Component";
use base "Entity::HostManager";

use strict;
use warnings;

use Kanopya::Exceptions;
use Entity::HostManager;
use Entity::ContainerAccess;
use Entity::ContainerAccess::NfsContainerAccess;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Administrator;
use NetworkManager;
use General;
use Entity::Kernel;

my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {};
sub getAttrDef { return ATTR_DEF; }

=head2 getBootPolicies

    Desc: return a list containing boot policies available

=cut

sub getBootPolicies {
    return (Entity::HostManager->BOOT_POLICIES->{pxe_iscsi},
            Entity::HostManager->BOOT_POLICIES->{pxe_nfs},
            Entity::HostManager->BOOT_POLICIES->{virtual_disk});
}

sub getHostType {
    return "Virtual Machine";
}

sub getConf {
    my $self = shift;
    my %conf = ();
    my $confindb = $self->{_dbix};
    if($confindb) {
        %conf = $confindb->get_columns();
    }

    my @repositories = ();
    my @available_accesses = ();
    my $repo_rs = $confindb->opennebula3_repositories;
    while (my $repo_row = $repo_rs->next) {
        my $container_access = Entity::ContainerAccess->get(
                                   id => $repo_row->get_column('container_access_id')
                               );
        push @repositories, {
            repository_name         => $repo_row->get_column('repository_name'),
            container_access_export => $container_access->getAttr(name => 'container_access_export'),
        }
    }

    my @container_accesses = Entity::ContainerAccess::NfsContainerAccess->search(hash => {});
    for my $access (@container_accesses) {
        push @available_accesses, {
            container_access_id   => $access->getAttr(name => 'container_access_id'),
            container_access_name => $access->getAttr(name => 'container_access_export'),
        }
    }

    $conf{container_accesses} = \@available_accesses;
    $conf{opennebula3_repositories} = \@repositories;
    return \%conf;
}

sub setConf {
    my $self = shift;
    my ($conf) = @_;

    my $repos = $conf->{opennebula3_repositories};
    delete $conf->{opennebula3_repositories};

    if(not $conf->{opennebula3_id}) {
        # new configuration -> create
        $self->{_dbix}->create($conf);
    } else {
        # old configuration -> update
        $self->{_dbix}->update($conf);
    }

    # Update the configuration of the component Mounttable of the cluster,
    # to automatically mount the images repositories.
    my $cluster = Entity::ServiceProvider->get(id => $self->getAttr(name => 'service_provider_id'));
    my $mounttable = $cluster->getComponent(name => "Mounttable", version => "1");

    my $oldconf = $mounttable->getConf();
    my @mountentries = @{$oldconf->{mountdefs}};
    for my $repo (@{$repos}) {
        if ($repo->{container_access_id}) {
            $self->{_dbix}->opennebula3_repositories->create($repo);

            my $container_access = Entity::ContainerAccess->get(
                                       id => $repo->{container_access_id}
                                   );

            my $mounttable_entry = {
                mounttable1_mount_dumpfreq   => 0,
                mounttable1_mount_filesystem => 'nfs',
                mounttable1_mount_point      => $conf->{image_repository_path} . '/' . $repo->{repository_name},
                mounttable1_mount_device     => $container_access->getAttr(name => 'container_access_export'),
                mounttable1_mount_options    => $container_access->getAttr(name => 'container_access_options'),
                mounttable1_mount_passnum    => 0,
            };
            push @mountentries, $mounttable_entry
        }
    }
    $mounttable->setConf({ mounttable_mountdefs => \@mountentries});
}

sub getNetConf {
    my $self = shift;
    my $port = $self->{_dbix}->get_column('port');
    return { $port => ['tcp'] };
}

sub needBridge { return 1; }

sub getTemplateDataOned {
    my $self = shift;
    my %data = $self->{_dbix}->get_columns();
    delete $data{opennebula3_id};
    delete $data{component_instance_id};
    return \%data;
}

sub getTemplateDataOnedInitScript {
    my $self = shift;
    my $opennebula =  $self->{_dbix};
    my $data = { install_dir => $opennebula->get_column('install_dir') };
    return $data;
}

sub getTemplateDataLibvirtbin {
    my $self = shift;
    return {};
}

sub getTemplateDataLibvirtd {
    my $self = shift;
    return {};
}

sub getHostConstraints {return "physical";}

sub createVirtualHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'ram', 'core' ]);

    my $adm =  Administrator->new();
    my $new_mac_address = $adm->{manager}->{network}->generateMacAddress();

    # Use the first kernel found...
    my $kernel = Entity::Kernel->find(hash => {});

    my $vm = Entity::Host->new(
                 service_provider_id => $self->getAttr(name => 'service_provider_id'),
                 host_manager_id     => $self->getAttr(name => 'entity_id'),
                 host_mac_address    => $new_mac_address,
                 host_serial_number  => "Virtual Host with mac $new_mac_address",
                 kernel_id           => $kernel->getAttr(name => 'entity_id'),
                 host_ram            => $args{ram},
                 host_core           => $args{core},
                 active              => 1,
             );

    $vm->save();
    $log->debug("return host with <" . $vm->getAttr(name => "host_id") . ">");
    return $vm;
}

### hypervisors manipulation ###

# declare an new hypervisor into database
# real declaration in opennebula must have been done
# since `hypervisor_id` is required

sub addHypervisor {
	my $self = shift;
	my %args = @_;
	General::checkParams(args => \%args, required => ['host_id', 'id']);
	$self->{_dbix}->create_related(
		'opennebula3_hypervisors',
		{ hypervisor_host_id => $args{host_id},
		  hypervisor_id		 => $args{id},
		}
	);
}


sub removeHypervisor {
	my $self = shift;
	my %args = @_;
	General::checkParams(args => \%args, required => ['host_id']);
	$self->{_dbix}->opennebula3_hypervisors->search({hypervisor_host_id=>$args{host_id}})->single()->delete;
}

sub getHypervisorIdFromHostId {
	my $self = shift;
	my %args = @_;
	General::checkParams(args => \%args, required => ['host_id']);
	my $id = $self->{_dbix}->opennebula3_hypervisors->search({hypervisor_host_id=>$args{host_id}})->single()->get_column('hypervisor_id');
	return $id;
}

### VMs manipulations ###

sub addVm {
	my $self = shift;
	my %args = @_;
	General::checkParams(args => \%args, required => ['host_id', 'id']);
	$self->{_dbix}->create_related(
		'opennebula3_vms',
		{ vm_host_id => $args{host_id},
		  vm_id      => $args{id},
		}
	);
}

sub removeVm {
	my $self = shift;
	my %args = @_;
	General::checkParams(args => \%args, required => ['host_id']);
	$self->{_dbix}->opennebula3_vms->search({vm_host_id=>$args{host_id}})->single()->delete;
}

sub getVmIdFromHostId {
	my $self = shift;
	my %args = @_;
	General::checkParams(args => \%args, required => ['host_id']);
	my $id = $self->{_dbix}->opennebula3_vms->search({vm_host_id=>$args{host_id}})->single()->get_column('vm_id');
	return $id;
}


# Execute host migration to a new hypervisor
sub migrateHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['host', 'hypervisor_dst', 'hypervisor_cluster']);
    $log->info('<<<<< hypervisor_dst: '.$args{hypervisor_dst}->getAttr(name => 'host_id').'  host: '.$args{host}->getAttr(name => 'host_id'));
    my $hypervisor_id = $self->getHypervisorIdFromHostId(host_id => $args{hypervisor_dst}->getAttr(name => "host_id"));

    my $vm_id = $self->getVmIdFromHostId(host_id => $args{host}->getAttr(name => "host_id"));

    my $opennebula3_hypervisor_id = $self->{_dbix}->opennebula3_hypervisors->search({hypervisor_id => $hypervisor_id})->single()->get_column('opennebula3_hypervisor_id'); 

    $self->{_dbix}->opennebula3_vms->search(
		{vm_id=>$vm_id})->single()->update(
			{ opennebula3_hypervisor_id => $opennebula3_hypervisor_id,
			  
		}
	);

	
}


sub updateVm {
	my $self = shift;
	my %args = @_;
	General::checkParams(args => \%args, required => ['vm_host_id', 'hypervisor_id', 'vnc_port']);
	my $opennebula3_hypervisor_id = $self->{_dbix}->opennebula3_hypervisors->search({hypervisor_id=>$args{hypervisor_id}})->single()->get_column('opennebula3_hypervisor_id');
	$self->{_dbix}->opennebula3_vms->search(
		{vm_host_id=>$args{vm_host_id}})->single()->update(
			{ opennebula3_hypervisor_id => $opennebula3_hypervisor_id,
			  vnc_port                  => $args{vnc_port},
		}
	);
}


=head1 DIAGNOSTICS

Exceptions are thrown when mandatory arguments are missing.
Exception : Kanopya::Exception::Internal::IncorrectParam

=head1 CONFIGURATION AND ENVIRONMENT

This module need to be used into Kanopya environment. (see Kanopya presentation)
This module is a part of Administrator package so refers to Administrator configuration

=head1 DEPENDENCIES

This module depends of

=over

=item KanopyaException module used to throw exceptions managed by handling programs

=item Entity::Component module which is its mother class implementing global component method

=back

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to <Maintainer name(s)> (<contact address>)

Patches are welcome.

=head1 AUTHOR

<HederaTech Dev Team> (<dev@hederatech.com>)

=head1 LICENCE AND COPYRIGHT

Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301 USA.

=cut

1;
