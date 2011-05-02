# NodeManager.pm - Object class of Node Manager included in Administrator

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
# Created 2 december 2010

=head1 NAME

NodeManager - Network Manager object

=head1 SYNOPSIS

    use NetworkManager;
    
    # Creates NetworkManager
    my $nodemgt = NodeManager->new();
    

=head1 DESCRIPTION

Node Manager allows to manipulate node instance. Node are couple of a cluster and a node.

=head1 METHODS

=cut

package NodeManager;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use Data::Dumper;
use NetAddr::IP;
use Kanopya::Exceptions;

my $log = get_logger("administrator");
my $errmsg;

=head2 NodeManager::new (%args)
	
	Class : Public
	
	Desc : Instanciate Node Manager object
	
	args: 
		_node_rs : DBIx : user login to access to administrator
	return: NodeManager instance
	
=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $self = {};
	if (! exists $args{node_rs} or ! defined $args{node_rs}){
		$errmsg = "NodeManager->new need a _node_rs named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	$self->{_node_rs} = $args{node_rs};
	$self->{adm} = $args{adm};
	bless $self, $class;
	$log->info("New Node Manager Loaded");
	return $self;
}

=head2 NodeManager::addNode (%args)
	
	Class : Public
	
	Desc : Create a new node instance in db.
	
	args: 
		cluster_id : Int : Cluster identifier
		motherboard_id : Int : Motherboard identifier
		master_node : Int : 0 or 1 to say if the motherboard is the master node
	return: Node identifier
	
=cut

sub addNode{
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{cluster_id} or ! defined $args{cluster_id}) ||
		(! exists $args{motherboard_id} or ! defined $args{motherboard_id}) ||
		(! exists $args{master_node} or ! defined $args{master_node})){
		$errmsg = "NodeManager->addNode need a cluster_id, motherboard_id and a master_node named argument!";
		$log->error($errmsg);	
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
		
	my $res =$self->{_node_rs}->create({cluster_id=>$args{cluster_id},
											motherboard_id =>$args{motherboard_id},
											master_node => $args{master_node}});
	return $res->get_column("node_id");
}

=head2 NodeManager::delNode (%args)
	
	Class : Public
	
	Desc : Remove a node instance in db.
	
	args: 
		cluster_id : Int : Cluster identifier
		motherboard_id : Int : Motherboard identifier
	
=cut

sub delNode{
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{cluster_id} or ! defined $args{cluster_id}) ||
		(! exists $args{motherboard_id} or ! defined $args{motherboard_id})){
		$errmsg = "NodeManager->delNode need a cluster_id and a motherboard_id named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	my $row = $self->{_node_rs}->search(\%args)->first;
	if(not defined $row) {
		$errmsg = "NodeManager->delNode : node representing motherboard $args{motherboard_id} and cluster $args{cluster_id} not found!";
		$log->error($errmsg);
		throw Kanopya::Exception::DB(error => $errmsg);
	}
	$row->delete;
}

=head2 NodeManager::getNodes (%args)
	
	Class : Public
	
	Desc : Get all nodes in a cluster.
	
	args: 
		cluster_id : Int : Cluster identifier
	return:
		array of Entity:Motherboard
	
=cut

sub getNodes {
	my $self = shift;
	my %args = @_;
	if (! exists $args{cluster_id} or ! defined $args{cluster_id}) {
		$errmsg = "Administrator->getNodes need a cluster_id named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	my $nodes =  $self->{_node_rs}->search({ cluster_id => $args{cluster_id}});
	my $motherboards = [];
	while (my $n = $nodes->next) {
		push @$motherboards, $self->{adm}->getEntity(type => 'Motherboard', id => $n->get_column('motherboard_id'));
	}
	return $motherboards;
}


1;
