# Entity::Gp.pm  

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

Entity::Gp

=head1 SYNOPSIS

=head1 DESCRIPTION

blablabla

=cut

package Entity::Gp;
use base "Entity";

use strict;
use warnings;
use Kanopya::Exceptions;
use Administrator;
use Data::Dumper;
use Log::Log4perl "get_logger";


our $VERSION = "1.00";

my $log = get_logger("webui");
my $errmsg;

use constant ATTR_DEF => {
			gp_name			=> {pattern			=> '^\w*$',
										is_mandatory	=> 1,
										is_extended		=> 0,
										is_editable		=> 1},
			gp_desc			=> {pattern			=> '\w*', # Impossible to check char used because of \n doesn't match with \w
										is_mandatory	=> 0,
										is_extended 	=> 0,
										is_editable		=> 1},
			gp_system		=> {pattern			=> '^\d$',
										is_mandatory	=> 1,
										is_extended		=> 0,
										is_editable		=> 0},	
			gp_type			=> 	{pattern			=> '^\w*$',
										is_mandatory	=> 1,
										is_extended		=> 0,
										is_editable		=> 0},
};

sub methods {
	return {
		'create'	=> {'description' => 'create a new group', 
						'perm_holder' => 'mastergroup',
		},
		'get'		=> {'description' => 'view this group', 
						'perm_holder' => 'entity',
		},
		'update'	=> {'description' => 'save changes applied on this group', 
						'perm_holder' => 'entity',
		},
		'remove'	=> {'description' => 'delete this group', 
						'perm_holder' => 'entity',
		},
		'setperm'	=> {'description' => 'set permission on this group', 
						'perm_holder' => 'entity',
		},
		'appendEntity' => {'description' => 'add an element to group',
							'perm_holder' => 'entity',
		},					
		'removeEntity' => {'description' => 'remove an element from a group',
							'perm_holder' => 'entity',
		}, 
	};
}


=head2 get

	Class: public
	desc: retrieve a stored Entity::Gp instance
	args:
		id : scalar(int) : gp id
	return: Entity::Gp instance 

=cut

sub get {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{id} or ! defined $args{id})) { 
		$errmsg = "Entity::Gp->get need an id named argument!";	
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	my $admin = Administrator->new();
   	my $dbix_gp = $admin->{db}->resultset('Gp')->find($args{id});
   	if(not defined $dbix_gp) {
	   	$errmsg = "Entity::Gp->get : id <$args{id}> not found !";	
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
   	}   
   	# Entity::Gp->get method concerns an existing groups so we retrieve this groups'entity_id
   	my $entity_id = $dbix_gp->entitylink->get_column('entity_id');
   	my $granted = $admin->{_rightchecker}->checkPerm(entity_id => $entity_id, method => 'get');
   	if(not $granted) {
   		$errmsg = "Permission denied to get group with id $args{id}";
   		$log->error($errmsg);
   		throw Kanopya::Exception::Permission::Denied(error => $errmsg);
   	}
	
   	my $self = $class->SUPER::get( %args,  table => "Gp");
   	return $self;
}

=head2 getGroups

	Class: public
	desc: retrieve several Entity::Gp instances
	args:
		hash : hashref : where criteria
	return: @ : array of Entity::Gp instances
	
=cut

sub getGroups {
	my $class = shift;
    my %args = @_;
	my @objs = ();
    my ($rs, $entity_class);

	if ((! exists $args{hash} or ! defined $args{hash})) { 
		$errmsg = "Entity::Gp->getGroups need a hash named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	my $adm = Administrator->new();
   	return $class->SUPER::getEntities( %args,  type => "Gp");
}

=head2 new

	Class: Public
	desc:  constructor
	args: 
	return: Entity::Gp instance 
	
=cut

sub new {
	my $class = shift;
    my %args = @_;

	# Check attrs ad throw exception if attrs missed or incorrect
	my $attrs = $class->checkAttrs(attrs => \%args);
	
	# We create a new DBIx containing new entity (only global attrs)
	my $self = $class->SUPER::new( attrs => $attrs->{global},  table => "Gp");
	
	# Set the extended parameters
	#$self->{_ext_attrs} = $attrs->{extended};

    return $self;
}

=head2 create

=cut

sub create {
	my $self = shift;
	my $admin = Administrator->new();
	my $mastergroup_eid = $self->getMasterGroupEid();
   	my $granted = $admin->{_rightchecker}->checkPerm(entity_id => $mastergroup_eid, method => 'create');
   	if(not $granted) {
   		throw Kanopya::Exception::Permission::Denied(error => "Permission denied to create a new group");
   	}
 	$self->save();  	
}

=head2 update

=cut

sub update {}

=head2 remove

=cut

sub remove {}

=head2 getSize

	Class : public
	Desc  : return the number of entities in this group
	return : scalar (int)

=cut

sub getSize {
	my $self = shift;
	return $self->{_dbix}->ingroups->count();
}

=head2 getGroupsFromEntity

	Class: public
	desc: retrieve Entity::Gp instances that contains the Entity argument
	args:
		entity : Entity::* : an Entity instance
	return: @ : array of Entity::Gp instances
	
=cut

sub getGroupsFromEntity {
	my $class = shift;
    my %args = @_;
	my @groups = ();
    
	if ((! exists $args{entity} or ! defined $args{entity})) { 
		$errmsg = "Entity::Gp->getGroups need an entity named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	
	if(not $args{entity}->{_dbix}->in_storage ) { return @groups; } 
		
	my $adm = Administrator->new();
   	my $mastergroup = $args{entity}->getMasterGroupName();
	my $gp_rs = $adm->{db}->resultset('Gp')->search({
		-or => [
			'ingroups.entity_id' => $args{entity}->{_dbix}->get_column('entity_id'),
			'gp_name' => $mastergroup ]},
			
		{ 	'+columns' => [ 'gp_entity.entity_id' ], 
			join => [qw/ingroups gp_entity/] }
	);
	while(my $row = $gp_rs->next) {
		eval {
			my $group = $class->get(id => $row->get_column('gp_id'));
			push(@groups, $group);	
		};
		if($@) {
			my $exception = $@;
			if(Kanopya::Exception::Permission::Denied->caught()) {
				next;
			}
			else { $exception->rethrow(); } 
		}
	}
   	return @groups;
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
		$errmsg = "Entity::Gp->addEntity need an entity named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	my $entity_id = $args{entity}->{_dbix}->get_column('entity_id');
	$self->{_dbix}->ingroups->create({gp_id => $self->getAttr(name => 'gp_id'), entity_id => $entity_id} );
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
		$errmsg = "Entity::Gp->addEntity need an entity named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
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
	my $adm = Administrator->new();	
	my $type = $self->{_dbix}->get_column('gp_type');
	my $entity_class = 'Entity::'.$type;
	require 'Entity/'.$type.'.pm';
		
	my $entities_rs = $self->{_dbix}->ingroups;
	my $ids = [];
	my $idfield = lc($type)."_id";
	
	while(my $row = $entities_rs->next) {
		my $concret = $adm->{db}->resultset($type.'Entity')->search({entity_id => $row->get_column('entity_id')})->first;
		push @$ids, $concret->get_column("$idfield");
	}	
	
	my @objs = ();
	foreach my $id (@$ids) {
		my $e = eval { $entity_class->get(id => $id) };
		if($@) {
			my $exception = $@;
			if(Kanopya::Exception::Permission::Denied->caught()) {
				next;
			} 
			else { $exception->rethrow(); } 
		}
		push @objs, $e; 
	}	
		
	return @objs;
}

=head2 getExcludedEntities
	
	Desc : get all entities of the same type not contained in the group
	
	return : array of entities 

=cut

sub getExcludedEntities {
	my $self = shift;
	my $adm = Administrator->new();	
	my $type = $self->{_dbix}->get_column('gp_type');
	my $entity_class = 'Entity::'.$type;
	require 'Entity/'.$type.'.pm';
	
	my $entities_rs = $self->{_dbix}->ingroups;
	my $ids = [];
	my $idfield = lc($type)."_id";
	my $systemfield = lc($type)."_system";
	
	# retrieve groups elements ids 
	while(my $row = $entities_rs->next) {
		my $concret = $adm->{db}->resultset($type.'Entity')->search({entity_id => $row->get_column('entity_id')})->first;
		push @$ids, $concret->get_column("$idfield");
	}	
	
	# get (if granted) elements not already in the group 
	my @objs = ();
	my $where_clause = { "$idfield" => { -not_in => $ids }};
	# don't include system element
	if($adm->{db}->resultset($type)->result_source->has_column("$systemfield")) {
		$where_clause->{"$systemfield"} = 0;
	}
	
	#$log->debug(Dumper $where_clause);
	
	$entities_rs = $adm->{db}->resultset($type)->search($where_clause);
	while(my $row = $entities_rs->next) {
		my $entity = eval { $entity_class->get(id => $row->get_column("$idfield")); };
		if($@) {
			my $exception = $@;
			if(Kanopya::Exception::Permission::Denied->caught()) {
				next;
			} 
			else { $exception->rethrow(); }
		}
		else { push @objs, $entity; }	
	}
	
	return @objs;
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
	#print Dumper $attr_def;
	if (! exists $args{attrs} or ! defined $args{attrs}){ 
		$errmsg = "Entity::Gp->checkAttrs need an attrs hash named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}	

	my $attrs = $args{attrs};
	foreach my $attr (keys(%$attrs)) {
		if (exists $attr_def->{$attr}){
			$log->debug("Field <$attr> and value in attrs <$attrs->{$attr}>");
			if($attrs->{$attr} !~ m/($attr_def->{$attr}->{pattern})/){
				$errmsg = "Entity::Gp->checkAttrs detect a wrong value ($attrs->{$attr}) for param : $attr";
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
			$errmsg = "Entity::Gp->checkAttrs detect a wrong attr $attr !";
			$log->error($errmsg);
			throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
		}
	}
	foreach my $attr (keys(%$attr_def)) {
		if (($attr_def->{$attr}->{is_mandatory}) &&
			(! exists $attrs->{$attr})) {
				$errmsg = "Entity::Gp->checkAttrs detect a missing attribute $attr !";
				$log->error($errmsg);
				throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
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
		$errmsg = "Entity::Gp->checkAttr need a name and value named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	if (! defined $args{value} && $attr_def->{$args{name}}->{is_mandatory}){
		$errmsg = "Entity::Gp->checkAttr detect a null value for a mandatory attr ($args{name})";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
	}

	if (!exists $attr_def->{$args{name}}){
		$errmsg = "Entity::Gp->checkAttr invalid attr name : '$args{name}'";
		$log->error($errmsg);	
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}

	# Here check attr value
}

=head2 toString

	desc: return a string representation of the entity

=cut

sub toString {
	my $self = shift;
	my $string = $self->{_dbix}->get_column('gp_name');
	return $string;
}

1;
