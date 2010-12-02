# NetworkManager.pm - Object class of Network Manager included in Administrator

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
package NetworkManager;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use Data::Dumper;
use NetAddr::IP;
use McsExceptions;

my $log = get_logger("administrator");
my $errmsg;

sub new {
	my $class = shift;
	my %args = @_;
	my $self = {};
	if ((! exists $args{schemas} or ! defined $args{schemas})||
		(! exists $args{internalnetwork} or ! defined $args{internalnetwork})){
		$errmsg = "NetworkManager->new schemas named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	$self->{db} = $args{schemas};
	$self->{internalnetwork} = $args{internalnetwork};
	bless $self, $class;
}

=head2 addRoute

add new route to a public ip given its id
	args: 
		public_ip_id : String : Public ip identifier
		ip_destination : String : network address, format : XXX.XXX.XXX.XXX/XX
		gateway	: String : gateway ip address
=cut

sub addRoute {
	my $self = shift;
	my %args = @_;
	if (! exists $args{publicip_id} or ! defined $args{publicip_id} ||
		! exists $args{ip_destination} or ! defined $args{ip_destination} || 
		! exists $args{gateway} or ! defined $args{gateway}) {
		$errmsg = "NetworkManager->addRoute need publicip_id, ip_destination and gateway named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	# check valid ip_destination and gateway format
	my $destinationip = new NetAddr::IP($args{ip_destination});
	if(not defined $destinationip) {
		$errmsg = "NetworkManager->addRoute : wrong value for ip_destination!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);}
	
	my $gateway = new NetAddr::IP($args{gateway});
	if(not defined $gateway) {
		$errmsg = "NetworkManager->addRoute : wrong value for gateway!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	
	# try to create route
	eval {
		my $row = {ip_destination => $destinationip->addr, publicip_id => $args{publicip_id}};
		if($gateway) { $row->{gateway} = $gateway->addr; }
		$self->{db}->resultset('Route')->create($row);
	};
	if($@) { 
		$errmsg = "NetworkManager->addRoute: $@";
		$log->error($errmsg);
		throw Mcs::Exception::DB(error => $errmsg);
	}
	$log->debug("new route added to public ip");
}

=head2 getFreeInternalIP

return the first unused ip address in the internal network

=cut

sub getFreeInternalIP{
	my $self = shift;
	# retrieve internal network from config
	my $network = new NetAddr::IP(
		$self->{internalnetwork}->{ip},
		$self->{internalnetwork}->{mask},
	);
	
	my ($i, $row, $freeip) = 0;
	
	# try to find a matching motherboard of each ip of our network	
	while ($freeip = $network->nth($i)) {
		$row = $self->{db}->resultset('Motherboard')->find({ motherboard_internal_ip => $freeip->addr });
		
		# if no record is found for this ip address, it is free so we return it
		if(not defined $row) { 
			$row = $self->{db}->resultset('Powersupplycard')->find({ powersupplycard_ip => $freeip->addr });
			if(not defined $row) {
				return $freeip->addr; }}
		
		$log->debug($freeip->addr." is already used");
		$i++;
	}
	if(not defined $freeip) {
		$errmsg = "NetworkManager->getFreeInternalIP : all internal ip addresses seems to be used !";
		$log->error($errmsg);
		throw Mcs::Exception::Network(error => $errmsg);
	}
}

=head2 newPublicIP

add a new public ip address
	args: 
		ip_address
		ip_mask
	optional args:
		gateway
=cut

sub newPublicIP {
	my $self = shift;
	my %args = @_;
	if (! exists $args{ip_address} or ! defined $args{ip_address} || 
		! exists $args{ip_mask} or ! defined $args{ip_mask}) {
		$errmsg = "NetworkManager->newPublicIP need ip_address and ip_mask named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	# ip format valid ?
	my $pubip = new NetAddr::IP($args{ip_address}, $args{ip_mask});
	if(not defined $pubip) { 
		$errmsg = "NetworkManager->newPublicIP : wrong value for ip_address/ip_mask!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	} 
	
	my $gateway;
	if(exists $args{gateway} and defined $args{gateway}) {
		$gateway = new NetAddr::IP($args{gateway});
		if(not defined $gateway) {
			$errmsg = "NetworkManager->newPublicIP : wrong value for gateway!";
			$log->error($errmsg);
			throw Mcs::Exception::Internal(error => $errmsg);
		}
	}

	my $res;	
	# try to save public ip
	eval {
		my $row = {ip_address => $pubip->addr, ip_mask => $pubip->mask};
		if($gateway) { $row->{gateway} = $gateway->addr; }
		$res = $self->{db}->resultset('Publicip')->create($row);
		$log->debug("Public ip create and return ". $res->get_column("publicip_id"));
	};
	if($@) { 
		$errmsg = "NetworkManager->newPublicIP: $@";
		$log->error($errmsg);
		throw Mcs::Exception::DB(error => $errmsg); }
	$log->debug("new public ip created");
	return $res->get_column("publicip_id");
}

=head2 getPublicIPs

Get list of public ip addresses 
	return: array ref

=cut

sub getPublicIPs {
	my $self = shift;
	my $pubips = $self->{db}->resultset('Publicip')->search;
	my $pubiparray = [];
	while(my $ips = $pubips->next) {
		push @$pubiparray, {
			publicip_id => $ips->get_column('publicip_id'),
			cluster_id => $ips->get_column('cluster_id'),
			ip_address => $ips->get_column('ip_address'),
			ip_mask => $ips->get_column('ip_mask'),
			gateway =>$ips->get_column('gateway') 
		};
	}
	return $pubiparray;
}

=head2 getPublicIPs

Get list of unused public ip addresses 
	return: array ref

=cut

sub getFreePublicIPs {
	my $self = shift;
	my $pubips = $self->{db}->resultset('Publicip')->search({ cluster_id => undef });
	my $pubiparray = [];
	while(my $ips = $pubips->next) {
		push @$pubiparray, {
			publicip_id => $ips->get_column('publicip_id'),
			ip_address => $ips->get_column('ip_address'),
			ip_mask => $ips->get_column('ip_mask'),
			gateway =>$ips->get_column('gateway') 
		};
	}
	return $pubiparray;
}

=head2 delPublicIP

delete an unused public ip and its routes

=cut

sub delPublicIP {
	my $self = shift;
	my %args = @_;
	# arguments checking
	if (! exists $args{publicip_id} or ! defined $args{publicip_id}) { 
		$errmsg = "NetworkManager->delPublicIP need a publicip_id named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	
	# getting the row	
	my $row = $self->{db}->resultset('Publicip')->find( $args{publicip_id} );
	if(! defined $row) {
		$errmsg = "NetworkManager->delPublicIP : publicip_id $args{publicip_id} not found!";
		$log->error($errmsg);
		throw Mcs::Exception::DB(error => $errmsg);
	}
	
	# verify that it is not used by a cluster
	if(defined ($row->get_column('cluster_id'))) {
		$errmsg = "NetworkManager->delPublicIP : publicip_id $args{publicip_id} is used by a cluster!";	
		$log->error($errmsg);
		throw Mcs::Exception::DB(error => $errmsg);
	}
	
	# related routes are automatically deleted due to foreign key 
	$row->delete;
	$log->info("Public ip ($args{publicip_id}) deleted with its routes");
}

=head2 setClusterPublicIP

associate public ip and cluster
	args:	publicip_id, cluster_id 
	

=cut

sub setClusterPublicIP {
	my $self = shift;
	my %args = @_;
	if (! exists $args{publicip_id} or ! defined $args{publicip_id} ||
		! exists $args{cluster_id} or ! defined $args{cluster_id}) { 
		$errmsg = "NetworkManager->setClusterPublicIP need publicip_id and cluster_id named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	
	my $row = $self->{db}->resultset('Publicip')->find($args{publicip_id});
	# getting public ip row
	if(! defined $row) {
		$errmsg = "NetworkManager->setClusterPublicIP : publicip_id $args{publicip_id} not found!";
		$log->error($errmsg);
		throw Mcs::Exception::DB(error => $errmsg);
	}
	# try to set cluster_id to this ip
	eval {
		$row->set_column('cluster_id', $args{cluster_id});
		$row->update;
	};
	if($@) { 
		$errmsg = "NetworkManager->setClusterPublicIP : $@";
		$log->error($errmsg);
		throw Mcs::Exception::DB(error => $errmsg);
	}
	$log->info("Public ip $args{publicip_id} set to cluster $args{cluster_id}");
}

=head delRoute

delRoute delete a route given its id

=cut

sub delRoute {
	my $self = shift;
	my %args = @_;
	if (! exists $args{route_id} or ! defined $args{route_id}) {
		$errmsg = "NetworkManager->delRoute need a route_id named argument!"; 
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	
	my $row = $self->{db}->resultset('Route')->find($args{route_id});
	if(not defined $row) {
		$errmsg = "NetworkManager->delRoute : route_id $args{route_id} not found!";
		$log->error($errmsg);
		throw Mcs::Exception::DB(error => $errmsg);
	}
	$row->delete;
	$log->info("route ($args{route_id}) successfully deleted");	
}

=head getRoutes

return list of registered routes

=cut

sub getRoutes {
	my $self = shift;
	my $routes = $self->{db}->resultset('Route');
	my $routearray = [];
	while(my $r = $routes->next) {
		push @$routearray, {
			route_id => $r->get_column('route_id'),
			publicip_id => $r->get_column('publicip_id'),
			ip_destination => $r->get_column('ip_destination'),
			gateway =>$r->get_column('gateway') 
		};
	}
	return $routearray;
}
1;