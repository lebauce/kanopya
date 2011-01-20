# User.pm - This object allows to manipulate User
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
# Created 11 sept 2010

package Entity::User;
use base "Entity";

use strict;
use warnings;
use Kanopya::Exceptions;
use Log::Log4perl "get_logger";

our $VERSION = "1.00";

my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
			user_login			=> {pattern			=> '^\w*$',
										is_mandatory	=> 1,
										is_extended		=> 0,
										is_editable		=> 0},
			user_desc			=> {pattern			=> '\w*', # Impossible to check char used because of \n doesn't match with \w
										is_mandatory	=> 0,
										is_extended 	=> 0,
										is_editable		=> 1},
			user_password		=> {pattern			=> '^\w*$',
										is_mandatory	=> 1,
										is_extended		=> 0,
										is_editable		=> 1},
			user_firstname		=> {pattern			=> '^\w*$',
										is_mandatory	=> 1,
										is_extended		=> 0,
										is_editable		=> 0},
			user_lastname		=> {pattern			=> '^\w*$',
										is_mandatory	=> 1,
										is_extended		=> 0,
										is_editable		=> 0},
			user_email			=> {pattern			=> '\w*$',
										is_mandatory	=> 1,
										is_extended		=> 0,
										is_editable		=> 1},	
			user_creationdate	=> {pattern			=> '^*$',
										is_mandatory	=> 0,
										is_extended		=> 0,
										is_editable		=> 0},
			user_lastaccess		=> {pattern			=> '^\w*$',
										is_mandatory	=> 0,
										is_extended		=> 0,
										is_editable		=> 1},	
};

sub methods {
	return {
		class 		=> {
			create => 'create and save a new user',
		},
		instance 	=> {
			get			=> 'retrieve an existing user',
			update		=> 'save changes applied on a user',
			delete 		=> 'delete a user',
		}, 
	};
}

=head2 get

	Class: public
	desc: retrieve a stored Entity::User instance
	args:
		id : scalar(int) : user id
	return: Entity::User instance 

=cut

sub get {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{id} or ! defined $args{id})) { 
		$errmsg = "Entity::User->get need an id named argument!";	
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
  	
  	my $admin = Administrator->new();
   	my $dbix_user = $admin->{db}->resultset('User')->find($args{id});
   	if(not defined $dbix_user) {
	   	$errmsg = "Entity::User->get : id <$args{id}> not found !";	
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
   	}   	
   	
   	my $entity_id = $dbix_user->user_entities->first->get_column('entity_id');
   	my $granted = $admin->{_rightchecker}->checkPerm(entity_id => $entity_id, method => 'get');
   	if(not $granted) {
   		$errmsg = "Permission denied to get user with id $args{id}";
   		$log->error($errmsg);
   		throw Kanopya::Exception::Permission::Denied(error => $errmsg);
   	}
  	
  	my $self = $class->SUPER::get( %args,  table => "User");
   	return $self;
}

=head2 getUsers

	Class: public
	desc: retrieve several Entity::User instances
	args:
		hash : hashref : where criteria
	return: @ : array of Entity::User instances
	
=cut

sub getUsers {
	my $class = shift;
    my %args = @_;
	my @objs = ();
    my ($rs, $entity_class);

	if ((! exists $args{hash} or ! defined $args{hash})) { 
		$errmsg = "Entity::User->getUsers need a hash named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	my $adm = Administrator->new();
   	return $class->SUPER::getEntities( %args,  type => "User");
}

=head2 new

	Public class method
	desc:  Constructor
	args: 
	return: Entity::User instance 
	
=cut

sub new {
	my $class = shift;
    my %args = @_;

	# Check attrs ad throw exception if attrs missed or incorrect
	my $attrs = $class->checkAttrs(attrs => \%args);
		
	# We create a new DBIx containing new entity (only global attrs)
	my $self = $class->SUPER::new( attrs => $attrs->{global},  table => "User");
	
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
   		throw Kanopya::Exception::Permission::Denied(error => "Permission denied to create a new user");
   	}
   	
   	$self->{_dbix}->user_creationdate(\'NOW()');
   	$self->{_dbix}->user_lastaccess(undef);
   	$self->save();
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

=head2 delete

=cut

sub delete {
	my $self = shift;
	my $adm = Administrator->new();
	# delete method concerns an existing entity so we use his entity_id
   	my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'delete');
   	if(not $granted) {
   		throw Kanopya::Exception::Permission::Denied(
   			error => "Permission denied to delete user with id ".$self->getAttr(name =>'user_id')
   		);
   	}
	$self->SUPER::delete();
}

=head2 toString

	desc: return a string representation of the entity

=cut

sub toString {
	my $self = shift;
	my $string = $self->{_dbix}->get_column('user_firstname'). " ". $self->{_dbix}->get_column('user_lastname');
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
	my (%global_attrs, %ext_attrs);
	my $attr_def = ATTR_DEF;
	#print Dumper $attr_def;
	if (! exists $args{attrs} or ! defined $args{attrs}){ 
		$errmsg = "Entity::User->checkAttrs need an attrs hash named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}	

	my $attrs = $args{attrs};
	foreach my $attr (keys(%$attrs)) {
		if (exists $attr_def->{$attr}){
			$log->debug("Field <$attr> and value in attrs <$attrs->{$attr}>");
			if($attrs->{$attr} !~ m/($attr_def->{$attr}->{pattern})/){
				$errmsg = "Entity::User->checkAttrs detect a wrong value ($attrs->{$attr}) for param : $attr";
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
			$errmsg = "Entity::User->checkAttrs detect a wrong attr $attr !";
			$log->error($errmsg);
			throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
		}
	}
	foreach my $attr (keys(%$attr_def)) {
		if (($attr_def->{$attr}->{is_mandatory}) &&
			(! exists $attrs->{$attr})) {
				$errmsg = "Entity::User->checkAttrs detect a missing attribute $attr !";
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
		$errmsg = "Entity::User->checkAttr need a name and value named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	if (! defined $args{value} && $attr_def->{$args{name}}->{is_mandatory}){
		$errmsg = "Entity::User->checkAttr detect a null value for a mandatory attr ($args{name})";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
	}

	if (!exists $attr_def->{$args{name}}){
		$errmsg = "Entity::User->checkAttr invalid attr name : '$args{name}'";
		$log->error($errmsg);	
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}

	# Here check attr value
}

1;
