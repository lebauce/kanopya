# Motherboardmodel.pm - This object allows to manipulate Motherboard model
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
# Created 11 aug 2010
package Entity::Motherboardmodel;
use base "Entity";

use strict;
use warnings;

use McsExceptions;
use Administrator;
use Log::Log4perl "get_logger";
my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
	motherboardmodel_brand => { pattern => 'm//s', is_mandatory => 1, is_extended => 0 },
	motherboardmodel_name => { pattern => 'm//s', is_mandatory => 1, is_extended => 0 },
	motherboardmodel_chipset => { pattern => 'm//s', is_mandatory => 0, is_extended => 0 },
	motherboardmodel_processor_num => { pattern => 'm//s', is_mandatory => 0, is_extended => 0 },
	motherboardmodel_consumption => { pattern => 'm//s', is_mandatory => 1, is_extended => 0 },
	motherboardmodel_iface_num => { pattern => 'm//s', is_mandatory => 0, is_extended => 0 },
	motherboardmodel_ram_slot_num => { pattern => 'm//s', is_mandatory => 0, is_extended => 0 },
	motherboardmodel_ram_max => { pattern => 'm//s', is_mandatory => 0, is_extended => 0 },
	processormodel_id => { pattern => 'm//s', is_mandatory => 0, is_extended => 0 },
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
	#print Dumper $attr_def;
	if (! exists $args{attrs} or ! defined $args{attrs}){ 
		$errmsg = "Entity::Motherboardmodel->checkAttrs need an attrs hash named argument!";
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
			$errmsg = "Entity::Motherboardmodel->checkAttrs detect a wrong attr $attr !";
			$log->error($errmsg);
			throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
		}
	}
	foreach $attr (keys(%$attr_def)) {
		if (($attr_def->{$attr}->{is_mandatory}) &&
			(! exists $attrs->{$attr})) {
				$errmsg = "Entity::Motherboardmodel->checkAttrs detect a missing attribute $attr !";
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
		$errmsg = "Entity::Motherboardmodel->checkAttr need a name and value named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	if (! defined $args{value} && $attr_def->{$args{name}}->{is_mandatory}){
		$errmsg = "Entity::Motherboardmodel->checkAttr detect a null value for a mandatory attr ($args{name})";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::WrongValue(error => $errmsg);
	}

	if (!exists $attr_def->{$args{name}}){
		$errmsg = "Entity::Motherboardmodel->checkAttr invalid attr name : '$args{name}'";
		$log->error($errmsg);	
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}

	# Here check attr value
}

sub extension { return undef; }

sub get {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{id} or ! defined $args{id})) { 
		$errmsg = "Entity::Motherboardmodel->new need an id named argument!";	
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
   my $self = $class->SUPER::get( %args,  table => "Motherboardmodel");
   return $self;
}

sub getMotherboardmodels {
	my $class = shift;
    my %args = @_;
	my @objs = ();
    my ($rs, $entity_class);

	if ((! exists $args{hash} or ! defined $args{hash})) { 
		$errmsg = "Entity::getMotherboardmodels need a type and a hash named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	my $adm = Administrator->new();
   	return $class->SUPER::getEntities( %args,  type => "Motherboardmodel");
}

sub new {
	my $class = shift;
    my %args = @_;

	# Check attrs ad throw exception if attrs missed or incorrect
	my $attrs = $class->checkAttrs(attrs => \%args);
	
	# We create a new DBIx containing new entity (only global attrs)
	my $self = $class->SUPER::new( attrs => $attrs->{global},  table => "Motherboardmodel");
	
	# Set the extended parameters
	$self->{_ext_attrs} = $attrs->{extended};

    return $self;

}

=head2 toString

	desc: return a string representation of the entity

=cut

sub toString {
	my $self = shift;
	my $string = $self->{_dbix}->get_column('motherboardmodel_name')." ".$self->{_dbix}->get_column('motherboardmodel_brand');
	return $string;
}

1;
