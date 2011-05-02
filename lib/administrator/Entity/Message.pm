# Message.pm - This object allows to manipulate Message with user interface
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
# Created 3 sept 2010
package Entity::Message;
use base "Entity";

use strict;
use warnings;

use Kanopya::Exceptions;
use Data::Dumper;
use Log::Log4perl "get_logger";
my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
	user_id => {pattern => 'm//s', is_mandatory => 0, is_extended => 0},
	message_type => {pattern => 'm//s', is_mandatory => 1, is_extended => 0},
	message_content => {pattern => 'm//s', is_mandatory => 1, is_extended => 0},
	message_creationdate => {pattern => 'm//s', is_mandatory => 0, is_extended => 0},
};

sub get {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{id} or ! defined $args{id})) { 
		$errmsg = "Entity::Message->new need an id named argument!";	
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
   my $self = $class->SUPER::get( %args,  table => "Message");
   return $self;
}

sub getMessages {
	my $class = shift;
    my %args = @_;
	my @objs = ();
    my ($rs, $entity_class);

	if ((! exists $args{hash} or ! defined $args{hash})) { 
		$errmsg = "Entity::getMessages need a type and a hash named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	my $adm = Administrator->new();
   	return $class->SUPER::getEntities( %args,  type => "Message");
}

sub new {
	my $class = shift;
    my %args = @_;

	# Check attrs ad throw exception if attrs missed or incorrect
	my $attrs = $class->checkAttrs(attrs => \%args);
	
	# We create a new DBIx containing new entity (only global attrs)
	my $self = $class->SUPER::new( attrs => $attrs->{global},  table => "Message");
	
	# Set the extended parameters
	$self->{_ext_attrs} = $attrs->{extended};

    return $self;

}

sub extension { return undef; }

sub save {
	my $self = shift;
	$self->{_dbix}->set_column({'message_creationdate' => \"> CURRENT_DATE()"});
	$self->SUPER::save($self);
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

	if (! exists $args{attrs} or ! defined $args{attrs}){ 
		$errmsg = "Entity::Message<->checkAttrs need attrs named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
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
			$errmsg = "Entity::Message->checkAttrs detect a wrong attr $attr !";
			$log->error($errmsg);
			throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
		}
	}
	foreach $attr (keys(%$attr_def)) {
		if (($attr_def->{$attr}->{is_mandatory}) &&
			(! exists $attrs->{$attr})) {
				$errmsg = "Entity::Message->checkAttrs detect a missing attribute $attr !";
				$log->error($errmsg);
				throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
			}
	}
	#TODO Check if distribution id exist and are correct.
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
		$errmsg = "Entity::Message->checkAttr need a name and value named argument!"; 
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	if (!exists $attr_def->{$args{name}}){
		$errmsg = "Entity::Message->checkAttr invalid name"; 
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	# Here check attr value
}



1;