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
use McsExceptions;

use Log::Log4perl "get_logger";
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
			user_email			=> {pattern			=> '^*$',
										is_mandatory	=> 1,
										is_extended		=> 0,
										is_editable		=> 1},	
			user_creationdate	=> {pattern			=> '^*$',
										is_mandatory	=> 1,
										is_extended		=> 0,
										is_editable		=> 0},
			user_lastaccess		=> {pattern			=> '^\w*$',
										is_mandatory	=> 1,
										is_extended		=> 0,
										is_editable		=> 0},	
};



# contructor 

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
	return $self;
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
	my (%global_attrs, %ext_attrs, $attr);
	my $attr_def = ATTR_DEF;
	#print Dumper $attr_def;
	if (! exists $args{attrs} or ! defined $args{attrs}){ 
		$errmsg = "Entity::User->checkAttrs need an attrs hash named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}	

	my $attrs = $args{attrs};
	foreach $attr (keys(%$attrs)) {
		if (exists $attr_def->{$attr}){
			$log->debug("Field <$attr> and value in attrs <$attrs->{$attr}>");
			if($attrs->{$attr} !~ m/($attr_def->{$attr}->{pattern})/){
				$errmsg = "Entity::User->checkAttrs detect a wrong value ($attrs->{$attr}) for param : $attr";
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
			$errmsg = "Entity::User->checkAttrs detect a wrong attr $attr !";
			$log->error($errmsg);
			throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
		}
	}
	foreach $attr (keys(%$attr_def)) {
		if (($attr_def->{$attr}->{is_mandatory}) &&
			(! exists $attrs->{$attr})) {
				$errmsg = "Entity::User->checkAttrs detect a missing attribute $attr !";
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
		$errmsg = "Entity::User->checkAttr need a name and value named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	if (! defined $args{value} && $attr_def->{$args{name}}->{is_mandatory}){
		$errmsg = "Entity::User->checkAttr detect a null value for a mandatory attr ($args{name})";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::WrongValue(error => $errmsg);
	}

	if (!exists $attr_def->{$args{name}}){
		$errmsg = "Entity::User->checkAttr invalid attr name : '$args{name}'";
		$log->error($errmsg);	
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}

	# Here check attr value
}

sub extension {
	return undef;
}

1;
