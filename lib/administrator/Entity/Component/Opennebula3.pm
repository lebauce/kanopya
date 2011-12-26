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

use strict;
use warnings;

use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
use Data::Dumper;
use Administrator;
use NetworkManager;
use General;

my $log = get_logger("administrator");
my $errmsg;

=head2 new
B<Class>   : Public
B<Desc>    : This method allows to create a new instance of IAAS component and concretly Opennebula3.
B<args>    :
    B<component_id> : I<Int> : Identify component. Refer to component identifier table
    B<cluster_id> : I<int> : Identify cluster owning the component instance
B<Return>  : a new Entity::Component::Opennebula3 from parameters.
B<Comment>  : Like all component, instantiate it creates a new empty component instance.
        You have to populate it with dedicated methods.
B<throws>  :
    B<Kanopya::Exception::Internal::IncorrectParam> When missing mandatory parameters

=cut

sub new {
    my $class = shift;
    my %args = @_;
    my $self = $class->SUPER::new( %args);
    return $self;
}

sub getConf {
    my $self = shift;
    my %conf = ();
    my $confindb = $self->{_dbix}->opennebula3;
    if($confindb) {
        %conf = $confindb->get_columns();

    }
    return \%conf;
}

sub setConf {
    my $self = shift;
    my ($conf) = @_;

    if(not $conf->{opennebula3_id}) {
        # new configuration -> create
        $self->{_dbix}->create_related('opennebula3', $conf);
    } else {
        # old configuration -> update
        $self->{_dbix}->opennebula3->update($conf);
    }
}

sub getNetConf {
    my $self = shift;
    my $port = $self->{_dbix}->opennebula3->get_column('port');
    return { $port => ['tcp'] };
}

sub needBridge { return 1; }

sub insertDefaultConfiguration {
    my $self = shift;
    my %args = @_;
    my $conf = {}; # default config is provided by database default fields values
    $self->{_dbix}->create_related('opennebula3', $conf);
}

sub getTemplateDataOned {
    my $self = shift;
    my %data = $self->{_dbix}->opennebula3->get_columns();
    delete $data{opennebula3_id};
    delete $data{component_instance_id};
    return \%data;
}

sub getTemplateDataOnedInitScript {
    my $self = shift;
    my $opennebula =  $self->{_dbix}->opennebula3;
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
    
    General::checkParams(args => \%args, required => ['ram', 'core', 'cluster_id']);
    
    my $adm =  Administrator->new();
    my $new_mac_address = $adm->{manager}->{network}->generateMacAddress();
    
    my $vm = Entity::Host->new(
            host_mac_address => $new_mac_address,
            kernel_id => 1,
            host_serial_number => "Virtual Host with mac $new_mac_address",
            host_ram => $args{ram},
            host_core => $args{core},
            cloud_cluster_id => $args{cluster_id},
            active  => 1
            );
    $vm->save();
    $log->debug("return host with <" .$vm->getAttr(name=>"host_id").">");
    $self->addVm(host_id=>$vm->getAttr(name=>"host_id"));
    return $vm->getAttr(name=>"host_id");
}

### hypervisors manipulation ###

# declare an new hypervisor into database
# real declaration in opennebula must have been done
# since `hypervisor_id` is required 

sub addHypervisor {
	my $self = shift;
	my %args = @_;
	General::checkParams(args => \%args, required => ['host_id', 'id']);
	$self->{_dbix}->opennebula3->create_related(
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
	$self->{_dbix}->opennebula3->opennebula3_hypervisors->search({hypervisor_host_id=>$args{host_id}})->single()->delete;
}

sub getHypervisorIdFromHostId {
	my $self = shift;
	my %args = @_;
	General::checkParams(args => \%args, required => ['host_id']);
	my $id = $self->{_dbix}->opennebula3->opennebula3_hypervisors->search({hypervisor_host_id=>$args{host_id}})->single()->get_column('hypervisor_id');
	return $id;
}

### VMs manipulations ###

sub addVm {
	my $self = shift;
	my %args = @_;
	General::checkParams(args => \%args, required => ['host_id']);
	$self->{_dbix}->opennebula3->create_related(
		'opennebula3_vms',
		{ vm_host_id => $args{host_id} }
	);
}

sub removeVm {
	my $self = shift;
	my %args = @_;
	General::checkParams(args => \%args, required => ['host_id']);
	$self->{_dbix}->opennebula3->opennebula3_vms->find($args{host_id})->delete;
}

sub getVmIdFromHostId {
	my $self = shift;
	my %args = @_;
	General::checkParams(args => \%args, required => ['host_id']);
	my $id = $self->{_dbix}->opennebula3->opennebula3_vms->find($args{host_id})->get_column('vm_id');
	return $id;
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
