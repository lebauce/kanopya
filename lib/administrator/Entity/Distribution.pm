# Distribution.pm - This object allows to manipulate distribution configuration
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
# Created 3 july 2010
package Entity::Distribution;
use base "Entity";

use strict;
use warnings;

use McsExceptions;
use Data::Dumper;
use Administrator;
use Log::Log4perl "get_logger";
my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
	distribution_name => {pattern => "//", is_mandatory => 1, is_extended => 0},
	distribution_version => {pattern => "//", is_mandatory => 1, is_extended => 0},
	distribution_desc => {pattern => "//", is_mandatory => 1, is_extended => 0},
	etc_device_id => {pattern => "//", is_mandatory => 1, is_extended => 0},
	root_device_id => {pattern => "//", is_mandatory => 1, is_extended => 0}
};

sub get {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{id} or ! defined $args{id})) { 
		$errmsg = "Entity::Distribution->new need an id named argument!";	
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
   my $self = $class->SUPER::get( %args,  table => "Distribution");
   return $self;
}

sub getDistributions {
	my $class = shift;
    my %args = @_;
	my @objs = ();
    my ($rs, $entity_class);

	if ((! exists $args{hash} or ! defined $args{hash})) { 
		$errmsg = "Entity::getDistributions need a type and a hash named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	my $adm = Administrator->new();
   	return $class->SUPER::getEntities( %args,  type => "Distribution");
}

sub new {
	my $class = shift;
    my %args = @_;

	# Check attrs ad throw exception if attrs missed or incorrect
	my $attrs = $class->checkAttrs(attrs => \%args);
	
	# We create a new DBIx containing new entity (only global attrs)
	my $self = $class->SUPER::new( attrs => $attrs->{global},  table => "Distribution");
	
	# Set the extended parameters
	$self->{_ext_attrs} = $attrs->{extended};

    return $self;

}

=head getDevices 

get etc and root device attributes for this distribution

=cut

sub getDevices {
	my $self = shift;
	if(! $self->{_dbix}->in_storage) {
		$errmsg = "Entity::Distribution->getDevices must be called on an already save instance";
		$log->error($errmsg);
		throw Mcs::Exception(error => $errmsg);
	}
	
	my $etcrow = $self->{_dbix}->etc_device_id;
	my $rootrow = $self->{_dbix}->root_device_id;
	my $devices = {
		etc => { lv_id => $etcrow->get_column('lvm2_lv_id'), 
				 lvname => $etcrow->get_column('lvm2_lv_name'),
				 lvsize => $etcrow->get_column('lvm2_lv_size'),
				 lvfreespace => $etcrow->get_column('lvm2_lv_freespace'),	
				 filesystem => $etcrow->get_column('lvm2_lv_filesystem'),
				 vg_id => $etcrow->get_column('lvm2_vg_id'),
				 vgname => $etcrow->lvm2_vg_id->get_column('lvm2_vg_name'),
				 vgsize => $etcrow->lvm2_vg_id->get_column('lvm2_vg_size'),
				 vgfreespace => $etcrow->lvm2_vg_id->get_column('lvm2_vg_freespace'),
				},
		root => { lv_id => $rootrow->get_column('lvm2_lv_id'), 
				 lvname => $rootrow->get_column('lvm2_lv_name'),
				 lvsize => $rootrow->get_column('lvm2_lv_size'),
				 lvfreespace => $rootrow->get_column('lvm2_lv_freespace'),	
				 filesystem => $rootrow->get_column('lvm2_lv_filesystem'),
				 vg_id => $rootrow->get_column('lvm2_vg_id'),
				 vgname => $rootrow->lvm2_vg_id->get_column('lvm2_vg_name'),
				 vgsize => $rootrow->lvm2_vg_id->get_column('lvm2_vg_size'),
				 vgfreespace => $rootrow->lvm2_vg_id->get_column('lvm2_vg_freespace'),
		}
	};
	$log->info("Distribution etc and root devices retrieved from database");
	return $devices;
}

=head getProvidedComponents

get components provided by this distribution
return array ref containing hash ref 

=cut

sub getProvidedComponents {
	my $self = shift;
	if(! $self->{_dbix}->in_storage) {
		$errmsg = "Entity::Distribution->getComponents must be called on an already save instance";
		$log->error($errmsg);
		throw Mcs::Exception(error => $errmsg);
	}
	my $components = [];
	my $search = $self->{_dbix}->component_provideds->search(undef, 
		{ '+columns' => [ 'component_id.component_id', 
						'component_id.component_name', 
						'component_id.component_version', 
						'component_id.component_category' ],
			join => ['component_id'] } 
	);
	while (my $row = $search->next) {
		my $tmp = {};
		$tmp->{component_id} = $row->get_column('component_id');
		$tmp->{component_name} = $row->get_column('component_name');
		$tmp->{component_version} = $row->get_column('component_version');
		$tmp->{component_category} = $row->get_column('component_category');
		push @$components, $tmp;
	}
	return $components;
}

=head2 toString

	desc: return a string representation of the entity

=cut

sub toString {
	my $self = shift;
	my $string = $self->{_dbix}->get_column('distribution_name')." ".$self->{_dbix}->get_column('distribution_version');
	return $string;
}
1;