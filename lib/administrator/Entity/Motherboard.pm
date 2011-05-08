# Motherboard.pm - Object class of Ḿotherboard (Administrator side)
#    Copyright © 2011 Hedera Technology SAS
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

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

=head2 Motherboard Attributes

motherboardmodel_id : Int : Identifier of motherboard model.
processormodel_id : Int : Identifier of motherboard processor model
kernel_id : Int : kernel identifier which will be used by motherboard if non specified by cluster
motherboard_serial_number : String : This is the serial number attributed to motherboard
motherboard_mac_address : String : This is the main network interface mac address of the motherboard

motherboard_powersupply_id : Int : Facultative identifier to know which powersupplycard and port is used.
Powersupplyid is created during motherboard creation.
motherboard_desc :  String : This is a free field to enter a description of motherboard. It is generally used to 
specify owner, team, ...

active : Int : This is an internal parameter used to activate or deactivate resources on Kanopya System
motherboard_internal_ip : String : This another internally manage attribute, it allow to save internal ip of 
a motherboard when it is in a cluster
motherboard_hostname : Hostname is also internally managed. Motherboard hostname will be generated from the mac address
It is generated when a motherboard is added into a cluster
motherboard_initiatorname : This attributes is generated when a motherboard is added in a cluster and allow to connect
to internal storage to get the systemimage
etc_device_id : Int : This parameter corresponding to lv storage and iscsitarget generated 
when a motherboard is configured to be migrated into a cluster
motherboard_state : String : This parameter is internally managed, it allows to follow migration step.
It could be :
- WaitingStart
- Starting
- ReadyStart
- Up

- WaitingStop
- ReadyStop
- Stopping
- Down
=cut

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
			motherboard_ipv4_internal_id 	=> {pattern 		=> 'm/^\d*$',
											is_mandatory	=> 0,
											is_extended 	=> 0},
			motherboard_toto				=> {pattern 		=> '^.*$',
											is_mandatory	=> 0,
											is_extended 	=> 1}
			};

sub getAttrDef{
    return ATTR_DEF;
}
sub methods {
	return {
		'create'	=> {'description' => 'create a new motherboard', 
						'perm_holder' => 'mastergroup',
		},
		'get'		=> {'description' => 'view this motherboard', 
						'perm_holder' => 'entity',
		},
		'update'	=> {'description' => 'save changes applied on this motherboard', 
						'perm_holder' => 'entity',
		},
		'remove'	=> {'description' => 'delete this motherboard', 
						'perm_holder' => 'entity',
		},
		'activate'=> {'description' => 'activate this motherboard', 
						'perm_holder' => 'entity',
		},
		'deactivate'=> {'description' => 'deactivate this motherboard', 
						'perm_holder' => 'entity',
		},
		'addHarddisk'=> {'description' => 'add a hard disk to this motherboard', 
						'perm_holder' => 'entity',
		},
		'removeHarddisk'=> {'description' => 'remove a hard disk from this motherboard', 
						'perm_holder' => 'entity',
		},
		
		'setperm'	=> {'description' => 'set permissions on this motherboard', 
						'perm_holder' => 'entity',
		},
	};
}

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
   	my $entity_id = $motherboard->entitylink->get_column('entity_id');
   	my $granted = $admin->{_rightchecker}->checkPerm(entity_id => $entity_id, method => 'get');
   	if(not $granted) {
   		throw Kanopya::Exception::Permission::Denied(error => "Permission denied to get motherboard with id $args{id}");
   	}
   
   	my $self = $class->SUPER::get( %args, table=>"Motherboard");
   	$self->{_ext_attrs} = $self->getExtendedAttrs(ext_table => "motherboarddetails");
   	return $self;
}

sub setNodeState {
    my $self = shift;
	my %args = @_;
	# check arguments
	if((! exists $args{state} or ! defined $args{state})) {
	   	$errmsg = "Entity::Motherboard->setNodeState needs a state named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	$self->{_dbix}->node->update({'node_state' => $args{state}});
}

sub getNodeState {
    my $self = shift;

	return $self->{_dbix}->node->get_column('node_state');
}

=head2 Entity::Motherboard->becomeNode (%args)
	
	Class : Public
	
	Desc : Create a new node instance in db from motherboard linked to cluster (in params).
	
	args: 
		cluster_id : Int : Cluster identifier
		master_node : Int : 0 or 1 to say if the motherboard is the master node
	return: Node identifier
	
=cut

sub becomeNode{
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{cluster_id} or ! defined $args{cluster_id}) ||
		(! exists $args{master_node} or ! defined $args{master_node})){
		$errmsg = "Entity::Motherboard->becomeNode need a cluster_id and a master_node named argument!";
		$log->error($errmsg);	
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
    my $adm = Administrator->new();
	my $res =$adm->{db}->resultset('Node')->create({cluster_id=>$args{cluster_id},
											motherboard_id =>$self->getAttr(name=>'motherboard_id'),
											master_node => $args{master_node}});
	return $res->get_column("node_id");
}

sub becomeMasterNode{
    my $self = shift;

	my $row = $self->{_dbix}->node;
	if(not defined $row) {
		$errmsg = "Entity::Motherboard->becomeMasterNode :Motherboard ".$self->getAttr(name=>"motherboard_mac_address")." is not a node!";
		$log->error($errmsg);
		throw Kanopya::Exception::DB(error => $errmsg);
	}
	$row->update({master_node => 1});
}

=head2 Entity::Motherboard->stopToBeNode (%args)
	
	Class : Public
	
	Desc : Remove a node instance for a dedicated motherboard.
	
	args: 
		cluster_id : Int : Cluster identifier
	
=cut

sub stopToBeNode{
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{cluster_id} or ! defined $args{cluster_id})){
		$errmsg = "Motherboard->stopToBeNode need a cluster_id named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	my $row = $self->{_dbix}->node;
	if(not defined $row) {
		$errmsg = "Entity::Motherboard->stopToBeNode : node representing motherboard ".$self->getAttr(name=>"motherboard_mac_address")." and cluster $args{cluster_id} not found!";
		$log->error($errmsg);
		throw Kanopya::Exception::DB(error => $errmsg);
	}
	$row->delete;
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

sub getMotherboardFromIP {
	my $class = shift;
    my %args = @_;

	if ((! exists $args{ipv4_internal_ip} or ! defined $args{ipv4_internal_ip})) { 
		$errmsg = "Entity::getMotherboardFromIP need a type and a hash named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	my $adm = Administrator->new();
    my $net_id = $adm->{manager}->{network}->getInternalIPid(%args);
    return $class->SUPER::getEntities( hash=>{motherboard_ipv4_internal_id => $net_id},  type => "Motherboard");
}

sub getFreeMotherboards {
	my $class = shift;
	my @motherboards = $class->getMotherboards(hash => {active => 1, motherboard_state => 'down'});
	my @free;
	foreach my $m (@motherboards) {
		if(not $m->{_dbix}->node) {
			push @free, $m;
		}
	}
	return @free;
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

sub remove {
    my $self = shift;
    
    $log->debug("New Operation RemoveMotherboard with motherboard_id : <".$self->getAttr(name=>"motherboard_id").">");
    Operation->enqueue(
    	priority => 200,
        type     => 'RemoveMotherboard',
        params   => {motherboard_id => $self->getAttr(name=>"motherboard_id")},
    );
}




sub extension {
	return "motherboarddetails";
}

sub getHarddisks {
	
	my $self = shift;
	my $hds = [];
	my $harddisks = $self->{_dbix}->harddisks;
	while(my $hd = $harddisks->next) {
		my $tmp = {};
		$tmp->{harddisk_id} = $hd->get_column('harddisk_id');
		$tmp->{harddisk_device} = $hd->get_column('harddisk_device');
		push @$hds, $tmp;
	} 
	return $hds;
	 
}

sub addHarddisk {
	my $self = shift;
	my %args = @_;
	    
    if (! exists $args{device} or ! defined $args{device}) {
		$errmsg = "Entity::Motherboard->addHarddisk need a device named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	my $adm = Administrator->new();
	# addHarddisk method concerns an existing entity so we use his entity_id
   	my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'addHarddisk');
   	if(not $granted) {
   		throw Kanopya::Exception::Permission::Denied(error => "Permission denied to add a hard disk to this motherboard");
   	}
	
	$self->{_dbix}->harddisks->create({
		harddisk_device => $args{device},
		motherboard_id => $self->getAttr(name => 'motherboard_id'), 
	});
	
}

sub removeHarddisk {
	my $self = shift;
	my %args = @_;
	    
    if (! exists $args{harddisk_id} or ! defined $args{harddisk_id}) {
		$errmsg = "Entity::Motherboard->removeHarddisk need a harddisk_id named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}

	my $adm = Administrator->new();
	# removeHarddisk method concerns an existing entity so we use his entity_id
   	my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'removeHarddisk');
   	if(not $granted) {
   		throw Kanopya::Exception::Permission::Denied(error => "Permission denied to remove a hard disk from this motherboard");
   	}

	my $hd = $self->{_dbix}->harddisks->find($args{harddisk_id});
	$hd->delete();

}








sub activate{
    my $self = shift;
    
    $log->debug("New Operation ActivateMotherboard with motherboard_id : " . $self->getAttr(name=>'motherboard_id'));
    Operation->enqueue(priority => 200,
                   type     => 'ActivateMotherboard',
                   params   => {motherboard_id => $self->getAttr(name=>'motherboard_id')});
}

sub deactivate{
    my $self = shift;
    
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

=head2 getMacName

return Mac address with separator : replaced by _

=cut
sub getMacName {
	my $self = shift;
	my $mac = $self->getAttr(name => "motherboard_mac_address");
	$mac =~ s/\:/\_/mg;
	return $mac;
}


=head2 getEtcDev

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
	my $etcrow = $self->{_dbix}->etc_device;
	my $devices = {
		etc => { lv_id => $etcrow->get_column('lvm2_lv_id'), 
				 vg_id => $etcrow->get_column('lvm2_vg_id'),
				 lvname => $etcrow->get_column('lvm2_lv_name'),
				 vgname => $etcrow->lvm2_vg->get_column('lvm2_vg_name'),
				 size => $etcrow->get_column('lvm2_lv_size'),
				 freespace => $etcrow->get_column('lvm2_lv_freespace'),	
				 filesystem => $etcrow->get_column('lvm2_lv_filesystem')
				}	};
	$log->info("Motherboard etc and root devices retrieved from database");
	return $devices;
}

sub getInternalIP {
    my $self = shift;
    my $adm = Administrator->new();
    if ($self->getAttr(name=>"motherboard_ipv4_internal_id")) {
        return $adm->{manager}->{network}->getInternalIP(ipv4_internal_id => $self->getAttr(name=>"motherboard_ipv4_internal_id"));
    }
    return {};
#    if($self->{_dbix}->)
}

sub setInternalIP{
    my $self = shift;
    my %args = @_;
	if (! exists $args{ipv4_internal_address} or ! defined $args{ipv4_internal_address} || 
		! exists $args{ipv4_internal_mask} or ! defined $args{ipv4_internal_mask}) {
		$errmsg = "Motherboard->setInternalIP need ipv4_internal_address and ipv4_internal_mask named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
    my $adm = Administrator->new();
    my $net_id = $adm->{manager}->{network}->newInternalIP(%args);
    $self->setAttr(name => "motherboard_ipv4_internal_id", value => $net_id);
    return $net_id;
}

sub removeInternalIP{
    my $self = shift;
    
    my $internal_net_id = $self->getAttr(name =>"motherboard_ipv4_internal_id");
    
    $self->{_dbix}->update({'motherboard_ipv4_internal_id' => undef});
    my $adm = Administrator->new();
    my $net_id = $adm->{manager}->{network}->delInternalIP(ipv4_internal_id => $internal_net_id);

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
	return $self->{_dbix}->node->cluster->get_column('cluster_id');
}

sub getPowerSupplyCardId {
	my $self = shift;
	my $row = $self->{_dbix}->motherboard_powersupply;
	if (defined $row) {
		return $row->get_column('powersupplycard_id');}
	else {
		return;
	}
}

sub getModel {
	my $self = shift;
	my $model_row = $self->{_dbix}->motherboardmodel;
	if ( defined $model_row ) {
		return $model_row->get_columns();
	}
	return;
}

1;
