# Systemimage.pm - This object allows to manipulate Systemimage configuration
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
package Entity::Systemimage;
use base "Entity";

use strict;
use warnings;

use Kanopya::Exceptions;
use Administrator;
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
	systemimage_name => { pattern => '^[1-9a-zA-Z]*$',
						  is_mandatory => 1,
						  is_extended => 0 },
	
	systemimage_desc => { pattern => '^\w*$',
						  is_mandatory => 1,
						  is_extended => 0 },
	
	distribution_id => { pattern => '^\d*$',
						 is_mandatory => 1,
						 is_extended => 0 },
						 
	etc_device_id => { pattern => '^\d*$',
						 is_mandatory => 0,
						 is_extended => 0 },
	
	root_device_id => { pattern => '^\d*$',
						 is_mandatory => 0,
						 is_extended => 0 },		
						 
	active => { pattern => '^[01]$',
				is_mandatory => 0,
				is_extended => 0 },		
};

sub methods {
	return {
		class 		=> {
			create => 'create and save a new system image',
		},
		instance 	=> {
			get			=> 'retrieve an existing system image',
			update		=> 'save changes applied on a system image',
			delete 		=> 'delete a system image',
		}, 
	};
}

=head2 get

	Class: public
	desc: retrieve a stored Entity::Systemimage instance
	args:
		id : scalar(int) : user id
	return: Entity::Systemimage instance 

=cut

sub get {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{id} or ! defined $args{id})) { 
		$errmsg = "Entity::SystemImage->get need an id named argument!";	
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
   	
   	my $adm = Administrator->new();
   	my $dbix_systemimage = $adm->{db}->resultset('Systemimage')->find($args{id});
   	if(not defined $dbix_systemimage) {
	   	$errmsg = "Entity::Systemiamge->get : id <$args{id}> not found !";	
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
   	}   	
   	
   	my $entity_id = $dbix_systemimage->systemimage_entities->first->get_column('entity_id');
   	my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $entity_id, method => 'get');
   	if(not $granted) {
   		$errmsg = "Permission denied to get system image with id $args{id}";
   		$log->error($errmsg);
   		throw Kanopya::Exception::Permission::Denied(error => $errmsg);
   	}
   	
   	my $self = $class->SUPER::get( %args, table=>"Systemimage");
   	return $self;
}

=head2 getSystemimages

	Class: public
	desc: retrieve several Entity::Systemimage instances
	args:
		hash : hashref : where criteria
	return: @ : array of Entity::Systemimage instances
	
=cut

sub getSystemimages {
	my $class = shift;
    my %args = @_;

	if ((! exists $args{hash} or ! defined $args{hash})) { 
		$errmsg = "Entity::getSystemimage need a hash named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	my $adm = Administrator->new();
   	return $class->SUPER::getEntities( %args,  type => "Systemimage");
}

sub getSystemimage {
	my $class = shift;
    my %args = @_;

	if ((! exists $args{hash} or ! defined $args{hash})) { 
		$errmsg = "Entity::getSystemimage need a hash named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
   	my @systemimages = $class->SUPER::getEntities( %args,  type => "Systemimage");
    return pop @systemimages;
}

=head2 new

	Public class method
	desc:  Constructor
	args: 
	return: Entity::Systemimage instance 
	
=cut

sub new {
	my $class = shift;
    my %args = @_;

	# Check attrs ad throw exception if attrs missed or incorrect
	my $attrs = $class->checkAttrs(attrs => \%args);
	
	# We create a new DBIx containing new entity (only global attrs)
	my $self = $class->SUPER::new( attrs => $attrs->{global},  table => "Systemimage");
	
	# Set the extended parameters
	$self->{_ext_attrs} = $attrs->{extended};
    return $self;
}

=head2 create

=cut

sub create {
    my $self = shift;
    my %params = $self->getAttrs();
    my $admin = Administrator->new();
	my $mastergroup_eid = $self->getMasterGroupEid();
   	my $granted = $admin->{_rightchecker}->checkPerm(entity_id => $mastergroup_eid, method => 'create');
   	if(not $granted) {
   		throw Kanopya::Exception::Permission::Denied(error => "Permission denied to create a new system image");
   	}
    
    $log->debug("New Operation AddSystemimage with attrs : " . Dumper(%params));
    Operation->enqueue(
    	priority => 200,
        type     => 'AddSystemimage',
        params   => \%params,
    );
}

=head2 update

=cut

sub update {
	my $self = shift;
	my $adm = Administrator->new();
	# update method concerns an existing entity so we use his entity_id
   	my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'update');
   	if(not $granted) {
   		throw Kanopya::Exception::Permission::Denied(error => "Permission denied to update this entity");
   	}
	# TODO update implementation
}










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
	my (%global_attrs, %ext_attrs);
	my $attr_def = ATTR_DEF;

	if (! exists $args{attrs} or ! defined $args{attrs}){ 
		$errmsg = "Entity::Systemimage->checkAttrs need attrs named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}	

	my $attrs = $args{attrs};
	foreach my $attr (keys(%$attrs)) {
		if (exists $attr_def->{$attr}){
			$log->debug("Field <$attr> and value in attrs <$attrs->{$attr}>");
			$log->debug("Field <$attr> and value in attrs <$attrs->{$attr}>");
			if($attrs->{$attr} !~ m/($attr_def->{$attr}->{pattern})/){
				$errmsg = "Entity::Systemimage->checkAttrs detect a wrong value ($attrs->{$attr}) for param : $attr";
				$log->error($errmsg);
				$log->debug("Can't match $attr_def->{$attr}->{pattern} with $attrs->{$attr}");
				throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
			}
			if ($attr_def->{$attr}->{is_extended}){
				$ext_attrs{$attr} = $attrs->{$attr};
			}
			else {
				$global_attrs{$attr} = $attrs->{$attr};
			}
		}
		else {
			$errmsg = "Entity::Systemimage->checkAttrs detect a wrong attr $attr !";
			$log->error($errmsg);
			throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
		}
	}
	foreach my $attr (keys(%$attr_def)) {
		if (($attr_def->{$attr}->{is_mandatory}) &&
			(! exists $attrs->{$attr})) {
				$errmsg = "Entity::Systemimage->checkAttrs detect a missing attribute $attr !";
				$log->error($errmsg);
				throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
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
		$errmsg = "Entity::Systemimage->checkAttr need a name and value named argument!"; 
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	if (!exists $attr_def->{$args{name}}){
		$errmsg = "Entity::Systemimage->checkAttr invalid name"; 
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	# Here check attr value
}













sub activate{
    my $self = shift;
    
    my  $adm = Administrator->new();
    print "New Operation ActivateSystemimage with systemimage_id : " . $self->getAttr(name=>'systemimage_id');
    Operation->enqueue(priority => 200,
                   type     => 'ActivateSystemimage',
                   params   => {systemimage_id => $self->getAttr(name=>'systemimage_id')});
}

sub deactivate{
    my $self = shift;
    
    my  $adm = Administrator->new();
    print "New Operation DeactivateSystemimage with systemimage_id : " . $self->getAttr(name=>'systemimage_id');
    Operation->enqueue(priority => 200,
                   type     => 'DeactivateSystemimage',
                   params   => {systemimage_id => $self->getAttr(name=>'systemimage_id')});
}

=head2 toString

	desc: return a string representation of the entity

=cut

sub toString {
	my $self = shift;
	my $string = $self->{_dbix}->get_column('systemimage_name');
	return $string;
}

=head2 getDevices 

get etc and root device attributes for this systemimage

=cut

sub getDevices {
	my $self = shift;
	if(! $self->{_dbix}->in_storage) {
		$errmsg = "Entity::Systemimage->getDevices must be called on an already save instance";
		$log->error($errmsg);
		throw Kanopya::Exception(error => $errmsg);
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
	$log->info("Systemimage etc and root devices retrieved from database");
	return $devices;
}

=head2 getInstalledComponents

get components installed on this systemimage
return array ref containing hash ref 

=cut

sub getInstalledComponents {
	my $self = shift;
	if(! $self->{_dbix}->in_storage) {
		$errmsg = "Entity::Systemimage->getComponents must be called on an already save instance";
		$log->error($errmsg);
		throw Kanopya::Exception(error => $errmsg);
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
