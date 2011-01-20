# Motherboard.pm - Object class of Ḿotherboard (Administrator side)
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
# Created 14 july 2010
package Entity::Motherboard;
use base "Entity";

use strict;
use warnings;

use Kanopya::Exceptions;
use Operation;

use Log::Log4perl "get_logger";
use Data::Dumper;
my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
			  motherboardmodel_id	=>	{pattern			=> '^\d*$',
											is_mandatory	=> 1,
											is_extended		=> 0},
			  processormodel_id		=> {pattern			=> '^\d*$',
											is_mandatory	=> 1,
											is_extended 	=> 0},
			  kernel_id					=> {pattern			=> '^\d*$',
											is_mandatory	=> 1,
											is_extended		=> 0},
			  motherboard_serial_number	=> {pattern 		=> '^.*$',
											is_mandatory	=> 1,
											is_extended 	=> 0},
			  motherboard_powersupply_id=> {pattern 		=> '^\w*$',
											is_mandatory	=> 0,
											is_extended 	=> 0},
			  motherboard_desc			=> {pattern 		=> '\w*',
											is_mandatory	=> 0,
											is_extended 	=> 0},
			  active					=> {pattern 		=> '^[01]$',
											is_mandatory	=> 0,
											is_extended 	=> 0},
			  motherboard_mac_address	=> {pattern 		=> '^[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}$',  # mac address format must be lower case
											is_mandatory	=> 1,		# to have udev persistent net rules work
											is_extended 	=> 0},
			  motherboard_internal_ip	=> {pattern 		=> '^.*$',
											is_mandatory	=> 0,
											is_extended 	=> 0},
			  motherboard_hostname		=> {pattern 		=> '^\w*$',
											is_mandatory	=> 0,
											is_extended 	=> 0},
			  motherboard_initiatorname	=> {pattern 		=> '^.*$',
											is_mandatory	=> 0,
											is_extended 	=> 0},
			  etc_device_id				=> {pattern 		=> 'm/^\d*$',
											is_mandatory	=> 0,
											is_extended 	=> 0},
			motherboard_state				=> {pattern 		=> '^up|down|starting:\d*|stopping:\d*$',
											is_mandatory	=> 0,
											is_extended 	=> 0},
			motherboard_toto				=> {pattern 		=> '^.*$',
											is_mandatory	=> 0,
											is_extended 	=> 1}
			};


sub methods {}

=head2 get

=cut

sub get {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{id} or ! defined $args{id})) { 
		$errmsg = "Entity::Motherboard->get need an id named argument!";	
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
   
   	my $admin = Administrator->new();
   	my $motherboard = $admin->{db}->resultset('Motherboard')->find($args{id});
   	if(not defined $motherboard) {
   		$errmsg = "Entity::Motherboard->get : id <$args{id}> not found !";	
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
   	} 
   	my $entity_id = $motherboard->motherboard_entities->first->get_column('entity_id');
   	my $granted = $admin->{_rightchecker}->checkPerm(entity_id => $entity_id, method => 'get');
   	if(not $granted) {
   		throw Kanopya::Exception::Permission::Denied(error => "Permission denied to get motherboard with id $args{id}");
   	}
   
   	my $self = $class->SUPER::get( %args, table=>"Motherboard");
   	$self->{_ext_attrs} = $self->getExtendedAttrs(ext_table => "motherboarddetails");
   	return $self;
}

=head2 getMotherboards

=cut 

sub getMotherboards {
	my $class = shift;
    my %args = @_;

	if ((! exists $args{hash} or ! defined $args{hash})) { 
		$errmsg = "Entity::getMotherboards need a hash named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	my $adm = Administrator->new();
   	return $class->SUPER::getEntities( %args,  type => "Motherboard");
}

sub getMotherboard {
	my $class = shift;
    my %args = @_;

	if ((! exists $args{hash} or ! defined $args{hash})) { 
		$errmsg = "Entity::getMotherboard need a type and a hash named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
   	my @Motherboards = $class->SUPER::getEntities( %args,  type => "Motherboard");
    return pop @Motherboards;
}

=head2 new

=cut

sub new {
	my $class = shift;
    my %args = @_;

	# Check attrs ad throw exception if attrs missed or incorrect
	my $attrs = $class->checkAttrs(attrs => \%args);
	
	# We create a new DBIx containing new entity (only global attrs)
	my $self = $class->SUPER::new( attrs => $attrs->{global},  table => "Motherboard");
	
	# Set the extended parameters
	$self->{_ext_attrs} = $attrs->{extended};
    return $self;

}

=head2 create

=cut

sub create {
    my $self = shift;
    
    my %params = $self->getAttrs();
    $log->debug("New Operation AddMotherboard with attrs : " . Dumper(%params));
    Operation->enqueue(priority => 200,
                   type     => 'AddMotherboard',
                   params   => \%params);
}

=head2 update

=cut

sub update {}

=head2 remove

=cut

sub remove {}

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
		$errmsg = "Entity::Motherboard->checkAttrs need an attrs hash named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}	

	my $attrs = $args{attrs};
	foreach my $attr (keys(%$attrs)) {
		if (exists $attr_def->{$attr}){
			$log->debug("Field <$attr> and value in attrs <$attrs->{$attr}>");
			if($attrs->{$attr} !~ m/($attr_def->{$attr}->{pattern})/){
				$errmsg = "Entity::Motherboard->checkAttrs detect a wrong value ($attrs->{$attr}) for param : $attr";
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
			$errmsg = "Entity::Motherboard->checkAttrs detect a wrong attr $attr !";
			$log->error($errmsg);
			throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
		}
	}
	foreach my $attr (keys(%$attr_def)) {
		if (($attr_def->{$attr}->{is_mandatory}) &&
			(! exists $attrs->{$attr})) {
				$errmsg = "Entity::Motherboard->checkAttrs detect a missing attribute $attr !";
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
		$errmsg = "Entity::Motherboard->checkAttr need a name and value named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	if (! defined $args{value} && $attr_def->{$args{name}}->{is_mandatory}){
		$errmsg = "Entity::Motherboard->checkAttr detect a null value for a mandatory attr ($args{name})";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
	}

	if (!exists $attr_def->{$args{name}}){
		$errmsg = "Entity::Motherboard->checkAttr invalid attr name : '$args{name}'";
		$log->error($errmsg);	
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}

	# Here check attr value
}

sub extension {
	return "motherboarddetails";
}












sub activate{
    my $self = shift;
    
    my  $adm = Administrator->new();
    $log->debug("New Operation ActivateMotherboard with motherboard_id : " . $self->getAttr(name=>'motherboard_id'));
    Operation->enqueue(priority => 200,
                   type     => 'ActivateMotherboard',
                   params   => {motherboard_id => $self->getAttr(name=>'motherboard_id')});
}

sub deactivate{
    my $self = shift;
    
    my  $adm = Administrator->new();
    $log->debug("New Operation EDeactivateMotherboard with motherboard_id : " . $self->getAttr(name=>'motherboard_id'));
    Operation->enqueue(priority => 200,
                   type     => 'DeactivateMotherboard',
                   params   => {motherboard_id => $self->getAttr(name=>'motherboard_id')});
}



=head2 toString

	desc: return a string representation of the entity

=cut

sub toString {
	my $self = shift;
	my $string = $self->{_dbix}->get_column('motherboard_mac_address');
	$string =~ s/\://g;
	return $string;
}

sub getEtcName {
	my $self = shift;
	my $mac = $self->getAttr(name => "motherboard_mac_address");
	$mac =~ s/\:/\_/mg;
	return "etc_". $mac;
}

=head getMacName

return Mac address with separator : replaced by _

=cut
sub getMacName {
	my $self = shift;
	my $mac = $self->getAttr(name => "motherboard_mac_address");
	$mac =~ s/\:/\_/mg;
	return $mac;
}


=head getEtcDev

get etc attributes used by this motherboard

=cut
sub getEtcDev {
	my $self = shift;
	if(! $self->{_dbix}->in_storage) {
		$errmsg = "Entity::Motherboard->getEtcDev must be called on an already save instance";
		$log->error($errmsg);
		throw Kanopya::Exception(error => $errmsg);
	}
	$log->info("retrieve etc attributes");
	my $etcrow = $self->{_dbix}->etc_device_id;
	my $devices = {
		etc => { lv_id => $etcrow->get_column('lvm2_lv_id'), 
				 vg_id => $etcrow->get_column('lvm2_vg_id'),
				 lvname => $etcrow->get_column('lvm2_lv_name'),
				 vgname => $etcrow->lvm2_vg_id->get_column('lvm2_vg_name'),
				 size => $etcrow->get_column('lvm2_lv_size'),
				 freespace => $etcrow->get_column('lvm2_lv_freespace'),	
				 filesystem => $etcrow->get_column('lvm2_lv_filesystem')
				}	};
	$log->info("Motherboard etc and root devices retrieved from database");
	return $devices;
}

sub generateHostname {
#	my $self = shift;
#	my $mac = $self->getAttr(name => 'motherboard_mac_address');	
#	$mac =~ s/://g;
#	return "node".$mac;
	my $self = shift;
	my %args = @_;
	my $hostname = "node";

	$log->debug("Create hostname with ip $args{'ip'}");
	my @tmp = split(/\./, $args{ip});

	$log->debug("differents ip part are <$tmp[0]> <$tmp[1]> <$tmp[2]> <$tmp[3]>");
	my $cpt = 3 - length $tmp[3];
	while ($cpt) {
		$hostname .= "0";
		$cpt--;
	}
	$hostname .= $tmp[3];
	$log->info("Hostname generated : $hostname");
	return $hostname;
}


sub getClusterId {
	my $self = shift;
	return $self->{_dbix}->nodes->first()->cluster_id->get_column('cluster_id');
}

sub getPowerSupplyCardId {
	my $self = shift;
	my $row = $self->{_dbix}->motherboard_powersupply_id;
	if (defined $row) {
		return $row->get_column('powersupplycard_id');}
	else {
		return;
	}
}
1;
