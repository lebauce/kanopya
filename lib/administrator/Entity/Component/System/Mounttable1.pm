# Mounttable1.pm - Mounttable1 component
# Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to the
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 4 sept 2010

=head1 NAME

<Entity::Component::System::Mounttable1> <Mounttable1 component concret class>

=head1 VERSION

This documentation refers to <Entity::Component::System::Mounttable1> version 1.0.0.

=head1 SYNOPSIS

use <Entity::Component::System::Mounttable1>;

my $component_instance_id = 2; # component instance id

Entity::Component::System::Mounttable1->get(id=>$component_instance_id);

# Cluster id

my $cluster_id = 3;

# Component id are fixed, please refer to component id table

my $component_id =2 

Entity::Component::System::Mounttable1->new(component_id=>$component_id, cluster_id=>$cluster_id);

=head1 DESCRIPTION

Entity::Component::System::Mounttable1 is class allowing to instantiate a Mounttable1 component
This Entity is empty but present methods to set configuration.

=head1 METHODS

=cut

package Entity::Component::System::Mounttable1;
use base "Entity::Component::System";

use strict;
use warnings;

use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("administrator");
my $errmsg;

=head2 new
B<Class>   : Public
B<Desc>    : This method allows to create a new instance of System component and concretly Mounttable1.
B<args>    : 
    B<component_id> : I<Int> : Identify component. Refer to component identifier table
    B<cluster_id> : I<int> : Identify cluster owning the component instance
B<Return>  : a new Entity::Component::System::Mounttable1 from parameters.
B<Comment>  : Like all component, instantiate it creates a new empty component instance.
        You have to populate it with dedicated methods.
B<throws>  : 
    B<Kanopya::Exception::Internal::IncorrectParam> When missing mandatory parameters
	
=cut

sub new {
	my $class = shift;
    my %args = @_;

	# We create a new DBIx containing new entity
	my $self = $class->SUPER::new( %args);

    return $self;

}

sub getConf {
	my $self = shift;
	my $conf = {};

	my $conf_rs = $self->{_dbix}->mounttable1s;
	my @mountdefs = ();
	while (my $conf_row = $conf_rs->next) {
		push @mountdefs, { 	mounttable1_id => $conf_row->get_column('mounttable1_id'),
							mounttable1_device => $conf_row->get_column('mounttable1_device'),
							mounttable1_mountpoint => $conf_row->get_column('mounttable1_mountpoint'),
							mounttable1_filesystem => $conf_row->get_column('mounttable1_filesystem'),
							mounttable1_options => $conf_row->get_column('mounttable1_options'),
							mounttable1_dumpfreq => $conf_row->get_column('mounttable1_dumpfreq'),
							mounttable1_passnum => $conf_row->get_column('mounttable1_passnum'),
						};
	}
	
	$conf->{mountdefs} = \@mountdefs;
	return $conf;
}

sub setConf {
	my $self = shift;
	my ($conf) = @_;
	$log->debug("la conf récupérée depuis le component mountab : ".Dumper ($conf));
	my $mountdefs_conf = $conf->{mounttable_mountdefs};
	
	# for each mount definition , we search it in db for update or deletion
	my $mountdefs_rs = $self->{_dbix}->mounttable1s;
	while(my $mountdef_row = $mountdefs_rs->next) {
		my $found = 0;
		my $mountdef_data;
		my $id = $mountdef_row->get_column('mounttable1_id');
		foreach	my $mountdef_conf (@$mountdefs_conf) {
		 	if($mountdef_conf->{mounttable1_id} == $id) {
		 		$found = 1;
		 		$mountdef_data = $mountdef_conf;
		 		last;
		 	}
		}
		if($found) {
	 		$mountdef_row->update($mountdef_data);
	 	} else {
	 		$mountdef_row->delete();
	 	}	 
	}
	
	foreach	my $mtdef (@$mountdefs_conf) {
		if (not exists $mtdef->{mounttable1_id}) {
				$self->{_dbix}->mounttable1s->create($mtdef);
		}
	}
}

# Insert default configuration in db for this component 
sub insertDefaultConfiguration() {
	my $self = shift;
	
	my @default_conf = (
		{ 	mounttable1_device => 'proc', mounttable1_mountpoint => '/proc', mounttable1_filesystem => 'proc',
			mounttable1_options => 'nodev,noexec,nosuid', mounttable1_dumpfreq => '0', mounttable1_passnum => '0' },
		{ 	mounttable1_device => 'sysfs', mounttable1_mountpoint => '/sys', mounttable1_filesystem => 'sysfs',
			mounttable1_options => 'defaults', mounttable1_dumpfreq => '0', mounttable1_passnum => '0' },
		{ 	mounttable1_device => 'tmpfs', mounttable1_mountpoint => '/tmp', mounttable1_filesystem => 'tmpfs',
			mounttable1_options => 'defaults', mounttable1_dumpfreq => '0', mounttable1_passnum => '0' },
		{ 	mounttable1_device => 'tmpfs', mounttable1_mountpoint => '/var/tmp', mounttable1_filesystem => 'tmpfs',
			mounttable1_options => 'defaults', mounttable1_dumpfreq => '0', mounttable1_passnum => '0' },
		{ 	mounttable1_device => 'tmpfs', mounttable1_mountpoint => '/var/run', mounttable1_filesystem => 'tmpfs',
			mounttable1_options => 'defaults', mounttable1_dumpfreq => '0', mounttable1_passnum => '0' },
		{ 	mounttable1_device => 'tmpfs', mounttable1_mountpoint => '/var/lock', mounttable1_filesystem => 'tmpfs',
			mounttable1_options => 'defaults', mounttable1_dumpfreq => '0', mounttable1_passnum => '0' },
	);
	
	foreach my $row (@default_conf) {
		$self->{_dbix}->mounttable1s->create( $row );
	}
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
