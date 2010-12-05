# PowerSupplyCard.pm - This object allows to manipulate PowerSupplyCard configuration
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
# Created 17 july 2010
package Entity::PowerSupplyCard;

use strict;
use McsExceptions;
use base "Entity";
use Log::Log4perl "get_logger";
my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
	powersupplycard_name => { pattern => 'm/\w*/s',
						  is_mandatory => 1,
						  is_extended => 0 },
	
	powersupplycard_ip => { pattern => 'm/\d+\.\d+\.\d+\.\d+/m',
						  is_mandatory => 1,
						  is_extended => 0 },
	
	powersupplycard_mac_address => { pattern => 'm//s',
						 is_mandatory => 1,
						 is_extended => 0 },
						 
	powersupplycard_model_id => { pattern => 'm//s',
						 is_mandatory => 0,
						 is_extended => 0 },
						 
	active => { pattern => 'm//s',
				is_mandatory => 0,
				is_extended => 0 },		
};



=head2 checkAttrs
	
	Desc : This function check if new object data are correct and sort attrs between extended and global
	args: 
		class : String : Real class to check
		data : hashref : Entity data to be checked
	return : hashref of hashref : a hashref containing 2 hashref, global attrs and extended ones

=cut

sub checkAttrs {
	# Remove class
	shift;
	my %args = @_;
	my (%global_attrs, %ext_attrs, $attr);
	my $attr_def = ATTR_DEF;

	if (! exists $args{attrs} or ! defined $args{attrs}){ 
		$errmsg = "Entity::PowerSupplyCard->checkAttrs need attrs named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}	

	my $attrs = $args{attrs};
	foreach $attr (keys(%$attrs)) {
		if (exists $attr_def->{$attr}){
			$log->debug("Field <$attr> and value in attrs <$attrs->{$attr}>");
			#TODO Check param with regexp in pattern field of struct
			if ($attr_def->{$attr}->{is_extended}){
				$ext_attrs{$attr} = $attrs->{$attr};
			}
			else {
				$global_attrs{$attr} = $attrs->{$attr};
			}
		}
		else {
			$errmsg = "Entity::PowerSupplyCard->checkAttrs detect a wrong attr $attr !";
			$log->error($errmsg);
			throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
		}
	}
	foreach $attr (keys(%$attr_def)) {
		if (($attr_def->{$attr}->{is_mandatory}) &&
			(! exists $attrs->{$attr})) {
				$errmsg = "Entity::PowerSupplyCard->checkAttrs detect a missing attribute $attr !";
				$log->error($errmsg);
				throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
			}
	}
	
	return {global => \%global_attrs, extended => \%ext_attrs};
}

=head2 checkAttr
	
	Desc : This function check new object attribute
	args: 
		name : String : Attribute name
		value : String : Attribute value
	return : No return value only throw exception if error

=cut

sub checkAttr {
	my $self = shift;
	my %args = @_;
	my $attr_def = ATTR_DEF;

	if ((! exists $args{name} or ! defined $args{name}) ||
		(! exists $args{value} or ! defined $args{value})) { 
		$errmsg = "Entity::PowerSupplyCard->checkAttr need a name and value named argument!"; 
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	if (!exists $attr_def->{$args{name}}){
		$errmsg = "Entity::PowerSupplyCard->checkAttr invalid name"; 
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	# Here check attr value
}

=head2 new

Desc : This function return new Entity::PowerSupplyCard instance
	args: 
		data : dbix row data
		rightschecker : 
	return : Entity::PowerSupplyCard instance

=cut

sub new {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{data} or ! defined $args{data}) ||
		(! exists $args{rightschecker} or ! defined $args{rightschecker})) { 
		$errmsg = "Entity::PowerSupplyCard->new need a data and rightschecker named argument!";
		$log->error($errmsg);	
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
    my $self = $class->SUPER::new( %args );
	return $self;
}

=head2 toString

	desc: return a string representation of the entity

=cut

sub toString {
	my $self = shift;
	my $string = $self->{_dbix}->get_column('PowerSupplyCard_name');
	return $string;
}

=head getDevices 

get etc and root device attributes for this PowerSupplyCard

=cut

sub getDevices {
	my $self = shift;
	if(! $self->{_dbix}->in_storage) {
		$errmsg = "Entity::PowerSupplyCard->getDevices must be called on an already save instance";
		$log->error($errmsg);
		throw Mcs::Exception(error => $errmsg);
	}
	$log->info("retrieve etc and root devices attributes");
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
	$log->info("PowerSupplyCard etc and root devices retrieved from database");
	return $devices;
}

=head getInstalledComponents

get components installed on this PowerSupplyCard
return array ref containing hash ref 

=cut

sub getInstalledComponents {
	my $self = shift;
	if(! $self->{_dbix}->in_storage) {
		$errmsg = "Entity::PowerSupplyCard->getComponents must be called on an already save instance";
		$log->error($errmsg);
		throw Mcs::Exception(error => $errmsg);
	}
	my $components = [];
	my $search = $self->{_dbix}->component_installeds->search(undef, 
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

1;
