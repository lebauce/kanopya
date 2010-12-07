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
package Entity::Powersupplycard;

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
	
    my $self = $class->SUPER::new( %args );
	return $self;
}

=head2 toString

	desc: return a string representation of the entity

=cut

sub toString {
	my $self = shift;
	my $string = $self->{_dbix}->get_column('powersupplycard_name'). " with mac address ". $self->{_dbix}->get_column('powersupplycard_mac_address') . " and ip " .$self->{_dbix}->get_column('powersupplycard_ip');;
	return $string;
}

=head2 addPowerSupplyCard

Desc : This function insert a new power supply card in Kanopya
	args: 
		name : String : Power supply card name (SN or internal naming convention)
		mac_address : String : mac_address allow to use dhcp to configure power supply card network
		internalip : String : internal ip get from  $adm->getFreeInternalIP();
	optionals args:
		model_id : Int : Power supply model id
=cut

#sub addPowerSupplyCard{
#	my $self = shift;
#	my %args = @_;
#	if ((! exists $args{name} or ! defined $args{name}) ||
#		(! exists $args{mac_address} or ! defined $args{mac_address}) ||
#		(! exists $args{internalip} or ! defined $args{internalip})){
#		$errmsg = "Administrator->addPowerSupplyCard need a name, mac_Address and an internalip named argument!";
#		$log->error($errmsg);
#		throw Mcs::Exception::Internal(error => $errmsg);
#	}
#	my $psc = {powersupplycard_name => $args{name},
#			   powersupplycard_mac_address => $args{mac_address}};
#	$psc->{powersupply_ip} = $args{internalip}; #$self->getFreeInternalIP();
#
#	if (exists $args{model_id} and defined $args{model_id}) {
#		$psc->{powersupply_model_id} = $args{model_id};
#	}
#	$self->{db}->resultset('Powersupplycard')->create($psc);
#	return;	
#}

#sub getPowerSupplyCards{
#	my $self = shift;
#	my %args = @_;	
#	my $r = $self->{db}->resultset('Powersupplycard')->search(undef, { 
#		order_by => { -desc => [qw/powersupplycard_id/], }, 
#	});
#	my @arr = ();
#	while (my $row = $r->next) {
#		push @arr, { 
#			'NAME' => $row->get_column('powersupplycard_name'), 
#			'IP' => $row->get_column('powersupplycard_ip'), 
#			'MAC' => $row->get_column('powersupplycard_mac_address')
#		};
#	}
#	return @arr;
#}

#sub findPowerSupplyCard{
#	my $self = shift;
#	my %args = @_;
#	if ((! exists $args{powersupplycard_id} or ! defined $args{powersupplycard_id})){
#		$errmsg = "Administrator->findPowerSupplyCard need an id named argument!";
#		$log->error($errmsg);
#		throw Mcs::Exception::Internal(error => $errmsg);
#	}
#	my $r = $self->{db}->resultset('Powersupplycard')->find($args{powersupplycard_id});
#	if(! $r){
#		$errmsg = "Administrator->findPowerSupplyCard can not find power supply card with id : $args{powersupplycard_id}";
#		$log->error($errmsg);
#		throw Mcs::Exception::Internal(error => $errmsg);
#	}
#	my $psc = {'powersupplycard_name' => $r->get_column('powersupplycard_name'), 
#				'powersupplycard_ip' => $r->get_column('powersupplycard_ip'), 
#				'powersupplycard_mac_address' => $r->get_column('powersupplycard_mac_address')};
#	return $psc;
#}

sub getMotherboardPort{
	my $self = shift;
	my %args = @_;
	$log->debug("PowerSupplyCard->getMotherboardPort");
	if ((! exists $args{motherboard_powersupply_id} or ! defined $args{motherboard_powersupply_id})){
		$errmsg = "PowerSupplyCard->getMotherboardPort need a motherboard_powersupply_id named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	return $self->{_dbix}->powersupplies()->find($args{motherboard_powersupply_id})->get_column('powersupplyport_number');
}

sub addPowerSupplyPort {
	my $self = shift;
	my %args = @_;
	$log->debug("PowerSupplyCard->AddPowerSupplyPort");
	if (! exists $args{powersupplyport_number} or ! defined $args{powersupplyport_number}){
		$errmsg = "PowerSupplyCard->AddPowerSupplyPort need a powersupplyport_number named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	my $powersupply_schema = $self->{_dbix}->powersupplies();
	my $powersupply = $powersupply_schema->create({
								powersupplycard_id => $self->getAttr(name=>"powersupplycard_id"),
								powersupplyport_number => $args{powersupplyport_number}});
	
	return $powersupply->get_column('powersupply_id');
}

sub delPowerSupply {
	my $self = shift;
	my %args = @_;
	if ((! exists $args{powersupply_id} or ! defined $args{powersupplycard_id})){
		$errmsg = "Powersupplycard->delPowerSupplyCard need a powersupply_id named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	my $powersupply = $self->{_dbix}->powersupplies()->find($args{powerwsupply_id})->delete();
}

sub getPowerSupply {
	my $self = shift;
	my %args = @_;
	if ((! exists $args{powersupply_id} or ! defined $args{powersupply_id})){
		$errmsg = "Powersupplycard->getPowerSupply need a powersupply_id named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	my $row = $self->{db}->resultset('Powersupply')->find($args{powersupply_id});
	my $powersupply = { powersupplycard_id => $row->get_column('powersupplycard_id'),
						powersupplyport_id => $row->get_column('powersupplyport_id')};
	return $powersupply;
}
1;
