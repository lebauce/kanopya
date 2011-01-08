# Cluster.pm - This object allows to manipulate cluster configuration
# Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology sas.

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
# Created 3 july 2010
package Entity::Cluster;
use base "Entity";

use strict;
use warnings;
use McsExceptions;
use Entity::Component;
use Entity::Motherboard;
use Administrator;
use General;
use Log::Log4perl "get_logger";
use Data::Dumper;


my $log = get_logger("administrator");
my $errmsg;
use constant ATTR_DEF => {
			cluster_name			=> {pattern			=> '^\w*$',
										is_mandatory	=> 1,
										is_extended		=> 0,
										is_editable		=> 0},
			cluster_desc			=> {pattern			=> '\w*', # Impossible to check char used because of \n doesn't match with \w
										is_mandatory	=> 0,
										is_extended 	=> 0,
										is_editable		=> 1},
			cluster_type			=> {pattern			=> '^.*$',
										is_mandatory	=> 0,
										is_extended		=> 0,
										is_editable		=> 0},
			cluster_min_node		=> {pattern 		=> '^\d*$',
										is_mandatory	=> 1,
										is_extended 	=> 0,
										is_editable		=> 1},
			cluster_max_node		=> {pattern			=> '^\d*$',
										is_mandatory	=> 1,
										is_extended		=> 0,
										is_editable		=> 1},
			cluster_priority		=> {pattern 		=> '^\d*$',
										is_mandatory	=> 1,
										is_extended 	=> 0,
										is_editable		=> 1},
			active					=> {pattern			=> '^[01]$',
										is_mandatory	=> 0,
										is_extended		=> 0,
										is_editable		=> 0},
			systemimage_id			=> {pattern 		=> '\d*',
										is_mandatory	=> 1,
										is_extended 	=> 0,
										is_editable		=> 0},
			kernel_id				=> {pattern 		=> '^\d*$',
										is_mandatory	=> 0,
										is_extended 	=> 0,
										is_editable		=> 1},
			cluster_state			=> {pattern 		=> '^up|down|starting:\d*|stopping:\d*$',
										is_mandatory	=> 0,
										is_extended 	=> 0,
										is_editable		=> 0}
			};


sub extension {
	return "clusterdetails";
}

sub getEntityTable {
	return "cluster";
}

=head2 checkAttr
	
	Desc : This function check if new object data are correct and sort attrs between extended and global
	args: 
		class : String : Real class to check
		data : hashref : Entity data to be checked
	return : hashref of hashref : a hashref containing 2 hashref, global attrs and extended ones

=cut

sub get {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{id} or ! defined $args{id})) { 
		$errmsg = "Entity::Cluster->new need an id named argument!";	
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
   my $self = $class->SUPER::get( %args,  table => "Cluster");
   $self->{_ext_attrs} = $self->getExtendedAttrs(ext_table => "clusterdetails");
   return $self;
}

sub getClusters {
	my $class = shift;
    my %args = @_;
	my @objs = ();
    my ($rs, $entity_class);

	if ((! exists $args{hash} or ! defined $args{hash})) { 
		$errmsg = "Entity::getClusters need a type and a hash named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	my $adm = Administrator->new();
   	return $class->SUPER::getEntities( %args,  type => "Cluster");
}

sub checkAttrs {
	# Remove class
	shift;
	my %args = @_;
	my (%global_attrs, %ext_attrs, $attr);
	my $struct = ATTR_DEF;

	if (! exists $args{attrs} or ! defined $args{attrs}) { 
		$errmsg = "Entity::Cluster->checkAttrs need an data hash and class named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}	

	my $attrs = $args{attrs};
	foreach $attr (keys(%$attrs)) {
		if (exists $struct->{$attr}){
			if($attrs->{$attr} !~ m/($struct->{$attr}->{pattern})/){
				$errmsg = "Entity::Cluster->checkAttrs detect a wrong value ($attrs->{$attr}) for param : $attr";
				$log->error($errmsg);
				$log->debug("Can't match $struct->{$attr}->{pattern} with $attrs->{$attr}");
				throw Mcs::Exception::Internal::WrongValue(error => $errmsg);
			}
			if ($struct->{$attr}->{is_extended}){
				$ext_attrs{$attr} = $attrs->{$attr};
			}
			else { $global_attrs{$attr} = $attrs->{$attr}; }
		}
		else {
			$errmsg = "Entity::Cluster->checkAttrs detect a wrong attr $attr !";
			$log->error($errmsg);
			throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
		}
	}
	foreach $attr (keys(%$struct)) {
		if (($struct->{$attr}->{is_mandatory}) &&
			(! exists $attrs->{$attr})) {
				$errmsg = "Entity::Cluster->checkAttrs detect a missing attribute $attr !";
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

sub checkAttr{
	my $self = shift;
	my %args = @_;
	my $struct = ATTR_DEF;
	
	if ((! exists $args{name} or ! defined $args{name}) ||
		(! exists $args{value} or ! defined $args{value})) { 
		$errmsg = "Entity::Cluster->checkAttr need a name and value named argument!";
		$log->error($errmsg);	
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	if (!exists $struct->{$args{name}}){
		$errmsg = "Entity::Cluster->checkAttr invalid name";	
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	# Here check attr value
}

# contructor
sub new {
	my $class = shift;
    my %args = @_;

	# Check attrs ad throw exception if attrs missed or incorrect
	my $attrs = $class->checkAttrs(attrs => \%args);
	
	# We create a new DBIx containing new entity (only global attrs)
	my $self = $class->SUPER::new( attrs => $attrs->{global},  table => "Cluster");
	
	# Set the extended parameters
	$self->{_ext_attrs} = $attrs->{extended};

    return $self;

}

=head2 toString

	desc: return a string representation of the entity

=cut

sub toString {
	my $self = shift;
	my $string = $self->{_dbix}->get_column('cluster_name');
	return $string;
}

=head2 getComponents
	
	Desc : This function get components used in a cluster. This function allows to select
			category of components or all of them.
	args: 
		administrator : Administrator : Administrator object to instanciate all components
		category : String : Component category
	return : a hashref of components, it is indexed on component_instance_id

=cut

sub getComponents{
	my $self = shift;
    my %args = @_;

	if ((! exists $args{category} or ! defined $args{category})) { 
		$errmsg = "Entity::Cluster->getComponent need a category named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
#	my $adm = Administrator->new();
	my $comp_instance_rs = $self->{_dbix}->search_related("component_instances", undef,
											{ '+columns' => [ "component_id.component_name", 
															  "component_id.component_category",
															  "component_id.component_version"], 
													join => ["component_id"]});
		
	my %comps;
	$log->debug("Category is $args{category}");
	while ( my $comp_instance_row = $comp_instance_rs->next ) {
		my $comp_category = $comp_instance_row->get_column('component_category');
		my $comp_instance_id = $comp_instance_row->get_column('component_instance_id');
		my $comp_name = $comp_instance_row->get_column('component_name');
		my $comp_version = comp_instance_row->get_column('component_version');
		if (($args{category} eq "all")||
			($args{category} eq $comp_category)){
			$log->debug("One component instance found with " . ref($comp_instance_row));
			$comps{$comp_instance_id} = "Entity::Component::$comp_category::$comp_name"."$comp_version"->get(id =>$comp_instance_id);
		}
	}
	return \%comps;
}

=head2 getComponent
	
	Desc : This function get component used in a cluster. This function allows to select
			a particular component with its name and version.
	args: 
		administrator : Administrator : Administrator object to instanciate all components
		name : String : Component name
		version : String : Component version
	return : a component instance

=cut

sub getComponent{
	my $self = shift;
    my %args = @_;

	if ((! exists $args{name} or ! defined $args{name}) ||
		(! exists $args{version} or ! defined $args{version})) { 
		$errmsg = "Entity::Cluster->getComponent needs a name, version and administrator named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	my $hash = {'component_id.component_name' => $args{name}, 'component_id.component_version' => $args{version}};
	my $comp_instance_rs = $self->{_dbix}->search_related("component_instances", $hash,
											{ '+columns' => [ "component_id.component_name",
															  "component_id.component_version",
															  "component_id.component_category"], 
													join => ["component_id"]});
		
	$log->debug("name is $args{name}, version is $args{version}");
	my $comp_instance_row = $comp_instance_rs->next;
	$log->debug("Comp name is " . $comp_instance_row->get_column('component_name'));
	$log->debug("Component instance found with " . ref($comp_instance_row));
	my $comp_category = $comp_instance_row->get_column('component_category');
	my $comp_instance_id = $comp_instance_row->get_column('component_instance_id');
	my $comp_name = $comp_instance_row->get_column('component_name');
	my $comp_version = $comp_instance_row->get_column('component_version');
	my $class= "Entity::Component::" . $comp_category . "::" . $comp_name . $comp_version;
	my $loc = General::getLocFromClass(entityclass=>$class);
	eval { require $loc; };
	return "$class"->get(id =>$comp_instance_id);
}

=head2 getSystemImage
	
	Desc : This function return the cluster's system image.
	args: 
		administrator : Administrator : Administrator object to instanciate all components
	return : a system image instance

=cut

sub getSystemImage {
	my $self = shift;
    my %args = @_;

	my $adm = Administrator->new();
	return Entity::Systemimage->get(id => $self->getAttr(name => 'systemimage_id'));
}

sub getMasterNodeIp {
	my $self = shift;
	my $node_instance_rs = $self->{_dbix}->search_related("nodes", { master_node => 1 })->single;
	if(defined $node_instance_rs) {
		my $node_ip = $node_instance_rs->motherboard_id->get_column('motherboard_internal_ip');
		$log->debug("Master node found and its ip is $node_ip");
		return $node_ip;
	} else {
		$log->debug("No Master node found for this cluster");
		return undef;
	}
}

sub getMasterNodeId {
	my $self = shift;
	my $node_instance_rs = $self->{_dbix}->search_related("nodes", { master_node => 1 })->single;
	if(defined $node_instance_rs) {
		my $id = $node_instance_rs->motherboard_id->get_column('motherboard_id');
		return $id;
	} else {
		return undef;
	}
}

=head2 addComponent

create a new component instance
this is the first step of cluster setting

=cut

sub addComponent {
	my $self = shift;
	my %args = @_;
	# check arguments
	if((! exists $args{component_id} or ! defined $args{component_id})) {
	   	$errmsg = "Entity::Cluster->addComponent needs component_id named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	my $componentinstance = Entity::Component->new(%args, cluster_id => $self->getAttr(name => "cluster_id"));
	$componentinstance->save();
}

=head2 removeComponent

remove a component instance and all its configuration
from this cluster

=cut

sub removeComponent {
	my $self = shift;
	my %args = @_;
	# check arguments
	if((! exists $args{administrator} or ! defined $args{administrator}) ||
	   (! exists $args{component_instance_id} or ! defined $args{component_instance_id})) {
	   	$errmsg = "Entity::Cluster->removeComponent needs administrator and component_instance_id named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	$args{administrator}->{db}->resultset('ComponentInstance')->find($args{component_instance_id})->delete;
	
}

=head2 getMotherboards
	
	Desc : This function get motherboards executing the cluster.
	args: 
		administrator : Administrator : Administrator object to instanciate all components
	return : a hashref of motherboard, it is indexed on motherboard_id

=cut

sub getMotherboards{
	my $self = shift;
    my %args = @_;

	my $motherboard_rs = $self->{_dbix}->nodes;
	my %motherboards;
	while ( my $node_row = $motherboard_rs->next ) {
		my $motherboard_row = $node_row->motherboard_id;
		$log->debug("Nodes found");
		my $motherboard_id = $motherboard_row->get_column('motherboard_id');
		$motherboards{$motherboard_id} = Entity::Motherboard->get (
						id => $motherboard_id,
						type => "Motherboard");
	}
	return \%motherboards;
}

sub getPublicIps {
	my $self = shift;
  
	my $publicip_rs = $self->{_dbix}->publicips;
	my $i =0;
	my @pub_ip =();
	while ( my $publicip_row = $publicip_rs->next ) {
		my $publicip = {address => $publicip_row->get_column('ip_address'),
						netmask => $publicip_row->get_column('ip_mask'),
						gateway => $publicip_row->get_column('gateway'),
						name 	=> "eth0:$i"};
		$i++;
		push @pub_ip, $publicip;
	}
	return \@pub_ip;
}
1;
