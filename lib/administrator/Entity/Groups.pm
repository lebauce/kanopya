# Entity::Groups.pm  

# Copyright (C) 2009, 2010, 2011, 2012, 2013
#   Hedera Technology Sas

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
# Created 16 july 2010

=head1 NAME

Entity::Groups

=head1 SYNOPSIS

=head1 DESCRIPTION

blablabla

=cut

package Entity::Groups;
use base "Entity";

use strict;
use warnings;
use McsExceptions;
use Administrator;
use Data::Dumper;
use Log::Log4perl "get_logger";


our $VERSION = "1.00";

my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
			groups_name			=> {pattern			=> '^\w*$',
										is_mandatory	=> 1,
										is_extended		=> 0,
										is_editable		=> 1},
			groups_desc			=> {pattern			=> '\w*', # Impossible to check char used because of \n doesn't match with \w
										is_mandatory	=> 0,
										is_extended 	=> 0,
										is_editable		=> 1},
			groups_system		=> {pattern			=> '^\d$',
										is_mandatory	=> 1,
										is_extended		=> 0,
										is_editable		=> 0},	
			groups_type			=> 	{pattern			=> '^\w*$',
										is_mandatory	=> 1,
										is_extended		=> 0,
										is_editable		=> 0},
};


=head2 new

	Class: Public
	desc:  constructor
	args: 
	return: Entity::Groups instance 
	
=cut

sub new {
	my $class = shift;
    my %args = @_;

	# Check attrs ad throw exception if attrs missed or incorrect
	my $attrs = $class->checkAttrs(attrs => \%args);
	
	# We create a new DBIx containing new entity (only global attrs)
	my $self = $class->SUPER::new( attrs => $attrs->{global},  table => "Groups");
	
	# Set the extended parameters
	#$self->{_ext_attrs} = $attrs->{extended};

    return $self;
}

=head2 get

	Class: public
	desc: retrieve a stored Entity::Groups instance
	args:
		id : scalar(int) : groups id
	return: Entity::Groups instance 

=cut

sub get {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{id} or ! defined $args{id})) { 
		$errmsg = "Entity::Groups->get need an id named argument!";	
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
   my $self = $class->SUPER::get( %args,  table => "Groups");
   #$self->{_ext_attrs} = $self->getExtendedAttrs(ext_table => "clusterdetails");
   return $self;
}

=head2 getGroups

	Class: public
	desc: retrieve several Entity::Groups instances
	args:
		hash : hashref : where criteria
	return: @ : array of Entity::Groups instances
	
=cut

sub getGroups {
	my $class = shift;
    my %args = @_;
	my @objs = ();
    my ($rs, $entity_class);

	if ((! exists $args{hash} or ! defined $args{hash})) { 
		$errmsg = "Entity::Groups->getGroups need a hash named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	my $adm = Administrator->new();
   	return $class->SUPER::getEntities( %args,  type => "Groups");
}

=head2 getGroupsFromEntity

	Class: public
	desc: retrieve Entity::Groups instances that contains the Entity argument
	args:
		entity : Entity::* : an Entity instance
	return: @ : array of Entity::Groups instances
	
=cut

sub getGroupsFromEntity {
	my $class = shift;
    my %args = @_;
	my @groups = ();
    
	if ((! exists $args{entity} or ! defined $args{entity})) { 
		$errmsg = "Entity::Groups->getGroups need a hash named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	
	if(not $args{entity}->{_dbix}->in_storage ) { return @groups; } 
		
	my $adm = Administrator->new();
   	my $mastergroup = ref $args{entity};
	$mastergroup =~ s/.*\:\://g;
   	my $groups_rs = $adm->{db}->resultset('Groups')->search({
		-or => [
			'ingroups.entity_id' => $args{entity}->{_dbix}->get_column('entity_id'),
			'groups_name' => $mastergroup ]},
			
		{ 	'+columns' => [ 'groups_entities.entity_id' ], 
			join => [qw/ingroups groups_entities/] }
	);
	while(my $row = $groups_rs->next) {
		push(@groups, $class->SUPER::get(id => $row->get_column('groups_id'), table => 'Groups'));
	}
   	return @groups;
}



=head2 toString

	desc: return a string representation of the entity

=cut

sub toString {
	my $self = shift;
	my $string = $self->{_dbix}->get_column('groups_name');
	return $string;
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
	my (%global_attrs, %ext_attrs, $attr);
	my $attr_def = ATTR_DEF;
	#print Dumper $attr_def;
	if (! exists $args{attrs} or ! defined $args{attrs}){ 
		$errmsg = "Entity::Groups->checkAttrs need an attrs hash named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}	

	my $attrs = $args{attrs};
	foreach $attr (keys(%$attrs)) {
		if (exists $attr_def->{$attr}){
			$log->debug("Field <$attr> and value in attrs <$attrs->{$attr}>");
			if($attrs->{$attr} !~ m/($attr_def->{$attr}->{pattern})/){
				$errmsg = "Entity::Groups->checkAttrs detect a wrong value ($attrs->{$attr}) for param : $attr";
				$log->error($errmsg);
				$log->debug("Can't match $attr_def->{$attr}->{pattern} with $attrs->{$attr}");
				throw Mcs::Exception::Internal::WrongValue(error => $errmsg);
			}
			if ($attr_def->{$attr}->{is_extended}){
				$ext_attrs{$attr} = $attrs->{$attr};
			}
			else {
				$global_attrs{$attr} = $attrs->{$attr};
			}
		}
		else {
			$errmsg = "Entity::Groups->checkAttrs detect a wrong attr $attr !";
			$log->error($errmsg);
			throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
		}
	}
	foreach $attr (keys(%$attr_def)) {
		if (($attr_def->{$attr}->{is_mandatory}) &&
			(! exists $attrs->{$attr})) {
				$errmsg = "Entity::Groups->checkAttrs detect a missing attribute $attr !";
				$log->error($errmsg);
				throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
			}
	}
	#TODO Check if id (systemimage, kernel, ...) exist and are correct.
	return {global => \%global_attrs, extended => \%ext_attrs};
}

=head2 checkAttr
	
	Desc : This function check new object attribute
	args: 
		name : String : Attribute name
		value : String : Attribute value
	return : No return value only throw exception if error

=cut

sub checkAttr{
	my $self = shift;
	my %args = @_;
	my $attr_def = ATTR_DEF;

	if ((! exists $args{name} or ! defined $args{name}) ||
		(! exists $args{value})) { 
		$errmsg = "Entity::Groups->checkAttr need a name and value named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	if (! defined $args{value} && $attr_def->{$args{name}}->{is_mandatory}){
		$errmsg = "Entity::Groups->checkAttr detect a null value for a mandatory attr ($args{name})";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::WrongValue(error => $errmsg);
	}

	if (!exists $attr_def->{$args{name}}){
		$errmsg = "Entity::Groups->checkAttr invalid attr name : '$args{name}'";
		$log->error($errmsg);	
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}

	# Here check attr value
}

sub extension {
	return undef;
}

=head2 appendEntity

	Class : Public
	
	Desc : append an entity object to the groups ; the entity must have been saved to the database before adding it to a group.
		
	args:
		entity : Entity::* object : an Entity object

=cut

sub appendEntity {
	my $self = shift;
	my %args = @_;
	if (! exists $args{entity} or ! defined $args{entity}) {  
		$errmsg = "Entity::Groups->addEntity need an entity named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	my $entity_id = $args{entity}->{_dbix}->get_column('entity_id');
	$self->{_dbix}->ingroups->create({groups_id => $self->getAttr(name => 'groups_id'), entity_id => $entity_id} );
	return;
}

=head2 removeEntity

	Class : Public
	
	Desc : remove an entity object from the groups
	
	args:
		entity : Entity::* object : an Entity object contained by the groups

=cut

sub removeEntity {
	my $self = shift;
	my %args = @_;
	if (! exists $args{entity} or ! defined $args{entity}) {  
		$errmsg = "Entity::Groups->addEntity need an entity named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	my $entity_id = $args{entity}->{_dbix}->get_column('entity_id');
	$self->{_dbix}->ingroups->find({entity_id => $entity_id})->delete();
	return;
}

=head2 getEntities

	Desc : get all entities contained in the group
	
	return : @: array of entities 

=cut

sub getEntities {
	my $self = shift;
			
	my $admin = Administrator->new();	
	my $type = $self->{_dbix}->get_column('groups_type');
	my $entity_ids = $admin->{db}->resultset('Ingroups')->search(
		{ groups_id => $self->getAttr('name' => 'groups_id') },
		{ columns => ['entity_id']}
	);
	my $ids = [];
	while(my $row = $entity_ids->next) {
		push(@$ids, $row->get_column('entity_id'));
	}
	
	$log->debug('NUMBER of ENTITIES FOUND : '.scalar(@$ids));
	my $field_id = lc($type)."_entities.entity_id";
	my @entities = ();
	my $module = "Entity/".$type.".pm";
	eval { require $module; };
	@entities = $self->SUPER::getEntities(type => $type, hash => { "$field_id" => \@$ids });
	$log->debug('NUMBER of ENTITIES OBJECTS RETRIEVED : '.scalar(@entities));
	return @entities;
}

=head2 getExcludedEntities
	
	Desc : get all entities of the same type not contained in the group
	
	return : array of entities 

=cut

sub getExcludedEntities {
	my $self = shift;
	my %args = @_;
	
	my $admin = Administrator->new();	
	my $type = $self->{_dbix}->get_column('groups_type');
	my $entity_ids = $admin->{db}->resultset('Ingroups')->search(
		{ groups_id => $self->getAttr('name' => 'groups_id') },
		{ columns => ['entity_id']}
	);
	my $ids = [];
	while(my $row = $entity_ids->next) {
		push(@$ids, $row->get_column('entity_id'));
	}
	
	$log->debug('NUMBER of ENTITIES FOUND : '.scalar(@$ids));
	my $field_id = lc($type)."_entities.entity_id";
	my @entities = ();
	my $module = "Entity/".$type.".pm";
	eval { require $module; };
	@entities = $self->SUPER::getEntities(type => $type, hash => { "$field_id" => { 'NOT IN' => \@$ids }});
	$log->debug('NUMBER of ENTITIES OBJECTS RETRIEVED : '.scalar(@entities));
	return @entities;
}


1;