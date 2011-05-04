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

use Kanopya::Exceptions;
use Entity::Component;
use Entity::Motherboard;
use Entity::Systemimage;
use Operation;
use Administrator;
use General;

use Log::Log4perl "get_logger";
use Data::Dumper;

our $VERSION = "1.00";

my $log = get_logger("administrator");
my $errmsg;
use constant ATTR_DEF => {
    cluster_name			=>  {pattern		=> '^\w*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 0},
    cluster_desc    		=>  {pattern        => '\w*', # Impossible to check char used because of \n doesn't match with \w
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
    cluster_type            =>  {pattern        => '^.*$',
                                 is_mandatory	=> 0,
                                 is_extended	=> 0,
                                 is_editable	=> 0},
    cluster_si_location     =>  {pattern        => '^(diskless|local)$',
                                 is_mandatory	=> 1,
                                 is_extended	=> 0,
                                 is_editable	=> 0},
    cluster_si_access_mode  =>  {pattern        => '^(ro|rw)$',
                                 is_mandatory	=> 1,
                                 is_extended	=> 0,
                                 is_editable	=> 0},
    cluster_si_shared       =>  {pattern        => '^(0|1)$',
                                 is_mandatory	=> 1,
                                 is_extended	=> 0,
                                 is_editable	=> 0},
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
								is_editable		=> 0},
	cluster_domainname      => {pattern 		=> '^[a-z0-9-]+(\.[a-z0-9-]+)+$',
								is_mandatory	=> 1,
								is_extended 	=> 0,
								is_editable		=> 0},
	cluster_nameserver		=> {pattern 		=> '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$',
								is_mandatory	=> 1,
								is_extended 	=> 0,
								is_editable		=> 0},
	
								
	};

sub methods {
	return {
		'create'	=> {'description' => 'create a new cluster', 
						'perm_holder' => 'mastergroup',
		},
		'get'		=> {'description' => 'view this cluster', 
						'perm_holder' => 'entity',
		},
		'update'	=> {'description' => 'save changes applied on this cluster', 
						'perm_holder' => 'entity',
		},
		'remove'	=> {'description' => 'delete this cluster', 
						'perm_holder' => 'entity',
		},
		'addNode'	=> {'description' => 'add a node to this cluster', 
						'perm_holder' => 'entity',
		},
		'removeNode'=> {'description' => 'remove a node from this cluster', 
						'perm_holder' => 'entity',
		},
		'activate'=> {'description' => 'activate this cluster', 
						'perm_holder' => 'entity',
		},
		'deactivate'=> {'description' => 'deactivate this cluster', 
						'perm_holder' => 'entity',
		},
		'start'=> {'description' => 'start this cluster', 
						'perm_holder' => 'entity',
		},
		'stop'=> {'description' => 'stop this cluster', 
						'perm_holder' => 'entity',
		},
		'setperm'	=> {'description' => 'set permissions on this cluster', 
						'perm_holder' => 'entity',
		},
		'addComponent'	=> {'description' => 'add a component to this cluster', 
						'perm_holder' => 'entity',
		},
		'removeComponent'	=> {'description' => 'remove a component from this cluster', 
						'perm_holder' => 'entity',
		},
		'configureComponents'	=> {'description' => 'configure components of this cluster', 
						'perm_holder' => 'entity',
		},
	};
}

=head2 get

=cut

sub get {
	my $class = shift;
    my %args = @_;
    
    if (! exists $args{id} or ! defined $args{id}) {
		$errmsg = "Entity::Cluster->new need an id named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}

   	my $admin = Administrator->new();
   	my $dbix_cluster = $admin->{db}->resultset('Cluster')->find($args{id});
   	if(not defined $dbix_cluster) {
	   	$errmsg = "Entity::Cluster->get : id <$args{id}> not found !";	
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
   	}   	
   	
   	my $entity_id = $dbix_cluster->entitylink->get_column('entity_id');
   	my $granted = $admin->{_rightchecker}->checkPerm(entity_id => $entity_id, method => 'get');
   	if(not $granted) {
   		throw Kanopya::Exception::Permission::Denied(error => "Permission denied to get cluster with id $args{id}");
   	}
   	my $self = $class->SUPER::get( %args,  table => "Cluster");
   	$self->{_ext_attrs} = $self->getExtendedAttrs(ext_table => "clusterdetails");
   	return $self;
}

=head2 getClusters

=cut

sub getClusters {
	my $class = shift;
    my %args = @_;
	my @objs = ();
    my ($rs, $entity_class);

	if ((! exists $args{hash} or ! defined $args{hash})) {
		$errmsg = "Entity::getClusters need a type and a hash named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
   	return $class->SUPER::getEntities( %args,  type => "Cluster");
}

sub getCluster {
	my $class = shift;
    my %args = @_;

	if ((! exists $args{hash} or ! defined $args{hash})) {
		$errmsg = "Entity::getClusters need a type and a hash named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
   	my @clusters = $class->SUPER::getEntities( %args,  type => "Cluster");
    return pop @clusters;
}

=head2 new

=cut

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
	
    my %params = $self->getAttrs();
    $log->debug("New Operation Create with attrs : " . %params);
    Operation->enqueue(
    	priority => 200,
        type     => 'AddCluster',
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

=head2 remove

=cut

sub remove {
	my $self = shift;
	my $adm = Administrator->new();
	# delete method concerns an existing entity so we use his entity_id
   	my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'delete');
   	if(not $granted) {
   		throw Kanopya::Exception::Permission::Denied(error => "Permission denied to delete this entity");
   	}
    my %params;
    $params{'cluster_id'}= $self->getAttr(name =>"cluster_id");
    $log->debug("New Operation Remove Cluster with attrs : " . %params);
    Operation->enqueue(
    	priority => 200,
        type     => 'RemoveCluster',
        params   => \%params,
    );
}

sub extension { return "clusterdetails"; }

sub activate {
    my $self = shift;

    $log->debug("New Operation ActivateCluster with cluster_id : " . $self->getAttr(name=>'cluster_id'));
    Operation->enqueue(priority => 200,
                   type     => 'ActivateCluster',
                   params   => {cluster_id => $self->getAttr(name=>'cluster_id')});
}

sub deactivate {
    my $self = shift;

    $log->debug("New Operation DeactivateCluster with cluster_id : " . $self->getAttr(name=>'cluster_id'));
    Operation->enqueue(priority => 200,
                   type     => 'DeactivateCluster',
                   params   => {cluster_id => $self->getAttr(name=>'cluster_id')});
}

=head2 checkAttr

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
	my $struct = ATTR_DEF;

	if (! exists $args{attrs} or ! defined $args{attrs}) {
		$errmsg = "Entity::Cluster->checkAttrs need an data hash and class named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}

	my $attrs = $args{attrs};
	foreach my $attr (keys(%$attrs)) {
		if (exists $struct->{$attr}){
			if($attrs->{$attr} !~ m/($struct->{$attr}->{pattern})/){
				$errmsg = "Entity::Cluster->checkAttrs detect a wrong value ($attrs->{$attr}) for param : $attr";
				$log->error($errmsg);
				$log->debug("Can't match $struct->{$attr}->{pattern} with $attrs->{$attr}");
				throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
			}
			if ($struct->{$attr}->{is_extended}){
				$ext_attrs{$attr} = $attrs->{$attr};
			}
			else { $global_attrs{$attr} = $attrs->{$attr}; }
		}
		else {
			$errmsg = "Entity::Cluster->checkAttrs detect a wrong attr $attr !";
			$log->error($errmsg);
			throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
		}
	}
	foreach my $attr (keys(%$struct)) {
		if (($struct->{$attr}->{is_mandatory}) &&
			(! exists $attrs->{$attr})) {
				$errmsg = "Entity::Cluster->checkAttrs detect a missing attribute $attr !";
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

sub checkAttr{
	my $self = shift;
	my %args = @_;
	my $struct = ATTR_DEF;

	if ((! exists $args{name} or ! defined $args{name}) ||
		(! exists $args{value} or ! defined $args{value})) {
		$errmsg = "Entity::Cluster->checkAttr need a name and value named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	if (!exists $struct->{$args{name}}){
		$errmsg = "Entity::Cluster->checkAttr invalid name $struct->{$args{name}}";
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

sub getComponents {
	my $self = shift;
    my %args = @_;

	if ((! exists $args{category} or ! defined $args{category})) {
		$errmsg = "Entity::Cluster->getComponent need a category named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
#	my $adm = Administrator->new();
	my $comp_instance_rs = $self->{_dbix}->search_related("component_instances", undef,
											{ '+columns' => [ "component.component_name",
															  "component.component_category",
															  "component.component_version"],
													join => ["component"]});

	my %comps;
	$log->debug("Category is $args{category}");
	while ( my $comp_instance_row = $comp_instance_rs->next ) {
		my $comp_category = $comp_instance_row->get_column('component_category');
		$log->debug("Component category: $comp_category");
		my $comp_instance_id = $comp_instance_row->get_column('component_instance_id');
		$log->debug("Component instance id: $comp_instance_id");
		my $comp_name = $comp_instance_row->get_column('component_name');
		$log->debug("Component name: $comp_name");
		my $comp_version = $comp_instance_row->get_column('component_version');
		$log->debug("Component version: $comp_version");
		if (($args{category} eq "all")||
			($args{category} eq $comp_category)){
			$log->debug("One component instance found with " . ref($comp_instance_row));
			my $class= "Entity::Component::" . $comp_category . "::" . $comp_name . $comp_version;
			my $loc = General::getLocFromClass(entityclass=>$class);
			eval { require $loc; };
			$comps{$comp_instance_id} = $class->get(id =>$comp_instance_id);
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
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}

	my $hash = {'component.component_name' => $args{name}, 'component.component_version' => $args{version}};
	my $comp_instance_rs = $self->{_dbix}->search_related("component_instances", $hash,
											{ '+columns' => [ "component.component_name",
															  "component.component_version",
															  "component.component_category"],
													join => ["component"]});

	$log->debug("name is $args{name}, version is $args{version}");
	my $comp_instance_row = $comp_instance_rs->next;
	if (not defined $comp_instance_row) {
		throw Kanopya::Exception::Internal(error => "Component with name '$args{name}' version $args{version} not installed on this cluster");
	}
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
	my $systemimage_id = $self->getAttr(name => 'systemimage_id');
	if($systemimage_id) {
		return Entity::Systemimage->get(id => $systemimage_id);
	} else {
		# only admin cluster has no systemimage ?
		return undef;
	}
}

sub getMasterNodeIp {
	my $self = shift;
	my $adm = Administrator->new();
	my $node_instance_rs = $self->{_dbix}->search_related("nodes", { master_node => 1 })->single;
	if(defined $node_instance_rs) {
		 my $motherboard_ipv4_internal_id = $node_instance_rs->motherboard->get_column('motherboard_ipv4_internal_id');
		 my $node_ip = $adm->{manager}->{network}->getInternalIP(ipv4_internal_id => $motherboard_ipv4_internal_id)->{ipv4_internal_address};
		$log->debug("Master node found and its ip is $node_ip");
		return $node_ip;
	} else {
		$log->debug("No Master node found for this cluster");
		return;
	}
}

sub getMasterNodeId {
	my $self = shift;
	my $node_instance_rs = $self->{_dbix}->search_related("nodes", { master_node => 1 })->single;
	if(defined $node_instance_rs) {
		my $id = $node_instance_rs->motherboard->get_column('motherboard_id');
		return $id;
	} else {
		return;
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
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}

	my $componentinstance = Entity::Component->new(%args, cluster_id => $self->getAttr(name => "cluster_id"));
	my $component_instance_id = $componentinstance->save();

	# Insert default configuration in db
	# Remark: we must get concrete instance here because the component->new (above) return an Entity::Component and not a concrete child component
	#		  There must be a way to do this more properly (component management).
	my $concrete_component = Entity::Component->getInstance(id => $component_instance_id);
	$concrete_component->insertDefaultConfiguration();

}

=head2 removeComponent

remove a component instance and all its configuration
from this cluster

=cut

sub removeComponent {
	my $self = shift;
	my %args = @_;
	# check arguments
	if((! exists $args{component_instance_id} or ! defined $args{component_instance_id})) {
	   	$errmsg = "Entity::Cluster->removeComponent needs a component_instance_id named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $component_instance = Entity::Component->get(id => $args{component_instance_id});
	$component_instance->delete;

}

=head2 getMotherboards

	Desc : This function get motherboards executing the cluster.
	args:
		administrator : Administrator : Administrator object to instanciate all components
	return : a hashref of motherboard, it is indexed on motherboard_id

=cut

sub getMotherboards {
	my $self = shift;
    #my %args = @_;

	my $motherboard_rs = $self->{_dbix}->nodes;
	my %motherboards;
	while ( my $node_row = $motherboard_rs->next ) {
		my $motherboard_row = $node_row->motherboard;
		$log->debug("Nodes found");
		my $motherboard_id = $motherboard_row->get_column('motherboard_id');
		eval { $motherboards{$motherboard_id} = Entity::Motherboard->get (
						id => $motherboard_id,
						type => "Motherboard") };
	}
	return \%motherboards;
}

=head2 getCurrentNodesCount

	class : public
	desc : return the current nodes count of the cluster

=cut

sub getCurrentNodesCount {
	my $self = shift;
	my $nodes = $self->{_dbix}->nodes;
	if ($nodes) {
	return $nodes->count;}
	else {
	    return 0;
	}
}



sub getPublicIps {
	my $self = shift;

	my $publicip_rs = $self->{_dbix}->ipv4_publics;
	my $i =0;
	my @pub_ip =();
	while ( my $publicip_row = $publicip_rs->next ) {
		my $publicip = {publicip_id => $publicip_row->get_column('ipv4_public_id'),
						address => $publicip_row->get_column('ipv4_public_address'),
						netmask => $publicip_row->get_column('ipv4_public_mask'),
						gateway => $publicip_row->get_column('ipv4_public_default_gw'),
						name 	=> "eth0:$i",
						cluster_id => $self->{_dbix}->get_column('cluster_id'),
		};
		$i++;
		push @pub_ip, $publicip;
	}
	return \@pub_ip;
}

=head2 getQoSConstraints
	
	Class : Public
	
	Desc : 
	
=cut

sub getQoSConstraints {
	my $self = shift;
	my %args = @_;
	
	# TODO retrieve from db (it's currently done by RulesManager, move here)
	return { max_latency => 22, max_abort_rate => 0.3 } ;
}

=head2 addNode

=cut

sub addNode {
	my $self = shift;
	my %args = @_;
	if((! exists $args{motherboard_id} or ! defined $args{motherboard_id})) {
	   	$errmsg = "Entity::Cluster->addNode needs motherboard_id named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
		
	my $adm = Administrator->new();
	# addNode method concerns an existing entity so we use his entity_id
   	my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'addNode');
   	if(not $granted) {
   		throw Kanopya::Exception::Permission::Denied(error => "Permission denied to add a node to this cluster");
   	}
    my %params = (
    	cluster_id => $self->getAttr(name =>"cluster_id"),
    	motherboard_id => $args{motherboard_id}, 
    );
    $log->debug("New Operation PreStartNode with attrs : " . %params);

    Operation->enqueue(
    	priority => 200,
#        type     => 'AddMotherboardInCluster',
        type     => 'PreStartNode',
        params   => \%params,
    );
}

=head2 removeNode 

=cut

sub removeNode {
	my $self = shift;
	my %args = @_;
	if((! exists $args{motherboard_id} or ! defined $args{motherboard_id})) {
	   	$errmsg = "Entity::Cluster->addNode needs motherboard_id named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
		
	my $adm = Administrator->new();
	# removeNode method concerns an existing entity so we use his entity_id
   	my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'removeNode');
   	if(not $granted) {
   		throw Kanopya::Exception::Permission::Denied(error => "Permission denied to remove a node from this cluster");
   	}
    my %params = (
    	cluster_id => $self->getAttr(name =>"cluster_id"),
    	motherboard_id => $args{motherboard_id}, 
    );
    $log->debug("New Operation AddMotherboardInCluster with attrs : " . %params);

    Operation->enqueue(
    	priority => 200,
        type     => 'PreStopNode',
        params   => \%params,
    );
}

=head2 start

=cut

sub start {
	my $self = shift;
	
	my $adm = Administrator->new();
	# start method concerns an existing entity so we use his entity_id
   	my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'start');
   	if(not $granted) {
   		throw Kanopya::Exception::Permission::Denied(error => "Permission denied to start this cluster");
   	}
    
    $log->debug("New Operation StartCluster with cluster_id : " . $self->getAttr(name=>'cluster_id'));
    Operation->enqueue(
    	priority => 200,
        type     => 'StartCluster',
        params   => { cluster_id => $self->getAttr(name =>"cluster_id") },
    );
}

=head2 stop 

=cut

sub stop {
	my $self = shift;
	
	my $adm = Administrator->new();
	# stop method concerns an existing entity so we use his entity_id
   	my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'stop');
   	if(not $granted) {
   		throw Kanopya::Exception::Permission::Denied(error => "Permission denied to stop this cluster");
   	}
    
    $log->debug("New Operation StopCluster with cluster_id : " . $self->getAttr(name=>'cluster_id'));
    Operation->enqueue(
    	priority => 200,
        type     => 'StopCluster',
        params   => { cluster_id => $self->getAttr(name =>"cluster_id") },
    );
}


1;
