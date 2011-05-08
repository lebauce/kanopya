# NetworkManager.pm - Object class of Network Manager included in Administrator

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
# Created 2 december 2010
package NetworkManager;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use Data::Dumper;
use NetAddr::IP;
use Kanopya::Exceptions;

my $log = get_logger("administrator");
my $errmsg;

=head2 NetworkManager::new (%args)
	
	Class : Public
	
	Desc : Instanciate Network Manager object
	
	args: 
		shemas : DBIx:Schema : Database schemas
		internalnetworl : hash : Internal network configuration
			ip : String : network address : XXX.XXX.XXX.XXX
			mask : String : network mask : XXX.XXX.XXX.XXX
	return: NetworkManager instance
	
=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $self = {};
	if ((! exists $args{schemas} or ! defined $args{schemas})||
		(! exists $args{internalnetwork} or ! defined $args{internalnetwork})){
		$errmsg = "NetworkManager->new schemas and internalnetwork named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	$self->{db} = $args{schemas};
	$self->{internalnetwork} = $args{internalnetwork};
	bless $self, $class;
	$log->info("New Network Manager Loaded");
	return $self;
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
		! exists $args{gateway} or ! defined $args{gateway} ||
		! exists $args{context} or ! defined $args{context}) {
		$errmsg = "NetworkManager->addRoute need publicip_id, ip_destination and gateway named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	# check valid ip_destination and gateway format
	my $destinationip = new NetAddr::IP($args{ip_destination});
	if(not defined $destinationip) {
		$errmsg = "NetworkManager->addRoute : wrong value for ip_destination!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);}
	
	my $gateway = new NetAddr::IP($args{gateway});
	if(not defined $gateway) {
		$errmsg = "NetworkManager->addRoute : wrong value for gateway!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	
	# try to create route
	eval {
		my $row = {ipv4_route_destination => $destinationip->addr, ipv4_route_gateway => $gateway->addr,ipv4_route_context=>$args{context}};
		$self->{db}->resultset('Ipv4Route')->create($row);
	};
	if($@) { 
		$errmsg = "NetworkManager->addRoute: $@";
		$log->error($errmsg);
		throw Kanopya::Exception::DB(error => $errmsg);
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
		$row = $self->{db}->resultset('Ipv4Internal')->find({ ipv4_internal_address => $freeip->addr });
		
		# if no record is found for this ip address, it is free so we return it
		if(not defined $row) { 
				return $freeip->addr; }
		$log->debug($freeip->addr." is already used");
		$i++;
	}
	if(not defined $freeip) {
		$errmsg = "NetworkManager->getFreeInternalIP : all internal ip addresses seems to be used !";
		$log->error($errmsg);
		throw Kanopya::Exception::Network(error => $errmsg);
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
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	# ip format valid ?
	my $pubip = new NetAddr::IP($args{ip_address}, $args{ip_mask});
	if(not defined $pubip) { 
		$errmsg = "NetworkManager->newPublicIP : wrong value for ip_address/ip_mask!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	} 
	
	my $gateway;
	if(exists $args{gateway} and defined $args{gateway}) {
		$gateway = new NetAddr::IP($args{gateway});
		if(not defined $gateway) {
			$errmsg = "NetworkManager->newPublicIP : wrong value for gateway!";
			$log->error($errmsg);
			throw Kanopya::Exception::Internal(error => $errmsg);
		}
	}

	my $res;	
	# try to save public ip
	eval {
		my $row = {ipv4_public_address => $pubip->addr, ipv4_public_mask => $pubip->mask};
		if($gateway) { $row->{ipv4_public_default_gw} = $gateway->addr; }
		$res = $self->{db}->resultset('Ipv4Public')->create($row);
		$log->debug("Public ip create and return ". $res->get_column("ipv4_public_id"));
	};
	if($@) { 
		$errmsg = "NetworkManager->newPublicIP: $@";
		$log->error($errmsg);
		throw Kanopya::Exception::DB(error => $errmsg); }
	$log->debug("new public ip created");
	return $res->get_column("ipv4_public_id");
}

sub getInternalIPId{
    my $self = shift;
	my %args = @_;
	if (! exists $args{ipv4_internal_address} or ! defined $args{ipv4_internal_address}) {
		$errmsg = "NetworkManager->getInternalIPId need ipv4_internal_address named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	my $internal_ip_row = $self->{db}->resultset('Ipv4Internal')->find({ipv4_internal_address => $args{ipv4_internal_address},key=>"ipv4_internal_address_UNIQUE"});
    return $internal_ip_row->get_column("ipv4_internal_id");
}

sub getInternalIP{
    my $self = shift;
	my %args = @_;
	if (! exists $args{ipv4_internal_id} or ! defined $args{ipv4_internal_id}) {
		$errmsg = "NetworkManager->getInternalIP need ipv4_internal_id named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	my %internal_ip_row = $self->{db}->resultset('Ipv4Internal')->find($args{ipv4_internal_id})->get_columns();
    return \%internal_ip_row;
}

=head2 newInternalIP

add a new internal ip address
	args: 
		ip_address
		ip_mask
	optional args:
		gateway
=cut

sub newInternalIP {
    #################################
    #TODO This method
	my $self = shift;
	my %args = @_;
	if (! exists $args{ipv4_internal_address} or ! defined $args{ipv4_internal_address} || 
		! exists $args{ipv4_internal_mask} or ! defined $args{ipv4_internal_mask}) {
		$errmsg = "NetworkManager->newInternalIP need ipv4_internal_address and ipv4_internal_mask named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	# ip format valid ?
	my $internalip = new NetAddr::IP($args{ipv4_internal_address}, $args{ipv4_internal_mask});
	if(not defined $internalip) { 
		$errmsg = "NetworkManager->newInternalIP : wrong value for ip_address/ip_mask!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	} 
	
	my $gateway;
	if(exists $args{ipv4_internal_default_gw} and defined $args{ipv4_internal_default_gw}) {
		$gateway = new NetAddr::IP($args{ipv4_internal_default_gw});
		if(not defined $gateway) {
			$errmsg = "NetworkManager->newInternalIP : wrong value for gateway!";
			$log->error($errmsg);
			throw Kanopya::Exception::Internal(error => $errmsg);
		}
	}

	my $res;	
	# try to save public ip
	eval {
		my $row = {ipv4_internal_address => $internalip->addr, ipv4_internal_mask => $internalip->mask};
		if($gateway) { $row->{ipv4_internal_default_gw} = $gateway->addr; }
		$res = $self->{db}->resultset('Ipv4Internal')->create($row);
		$log->debug("Public ip create and return ". $res->get_column("ipv4_internal_id"));
	};
	if($@) { 
		$errmsg = "NetworkManager->newInternalIP: $@";
		$log->error($errmsg);
		throw Kanopya::Exception::DB(error => $errmsg); }
	$log->debug("new internal ip created");
	return $res->get_column("ipv4_internal_id");
}



=head2 getPublicIPs

Get list of public ip addresses 
	return: array ref

=cut

sub getPublicIPs {
	my $self = shift;
	my $pubips = $self->{db}->resultset('Ipv4Public')->search;
	my $pubiparray = [];
	while(my $ips = $pubips->next) {
		push @$pubiparray, {
			publicip_id => $ips->get_column('ipv4_public_id'),
			cluster_id => $ips->get_column('cluster_id'),
			ip_address => $ips->get_column('ipv4_public_address'),
			ip_mask => $ips->get_column('ipv4_public_mask'),
			gateway =>$ips->get_column('ipv4_public_default_gw') 
		};
	}
	return $pubiparray;
}

=head2 getFreePublicIPs

Get list of unused public ip addresses 
	return: array ref

=cut

sub getFreePublicIPs {
	my $self = shift;
	my $pubips = $self->{db}->resultset('Ipv4Public')->search({ cluster_id => undef });
	my $pubiparray = [];
	while(my $ips = $pubips->next) {
		push @$pubiparray, {
			publicip_id => $ips->get_column('ipv4_public_id'),
			ip_address => $ips->get_column('ipv4_public_address'),
			ip_mask => $ips->get_column('ipv4_public_mask'),
			gateway =>$ips->get_column('ipv4_public_default_gw') 
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
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	
	# getting the row	
	my $row = $self->{db}->resultset('Ipv4Public')->find( $args{publicip_id} );
	if(! defined $row) {
		$errmsg = "NetworkManager->delPublicIP : publicip_id $args{publicip_id} not found!";
		$log->error($errmsg);
		throw Kanopya::Exception::DB(error => $errmsg);
	}
	
	# verify that it is not used by a cluster
	if(defined ($row->get_column('cluster_id'))) {
		$errmsg = "NetworkManager->delPublicIP : publicip_id $args{publicip_id} is used by a cluster!";	
		$log->error($errmsg);
		throw Kanopya::Exception::DB(error => $errmsg);
	}
	
	# related routes are automatically deleted due to foreign key 
	$row->delete;
	$log->info("Public ip ($args{publicip_id}) deleted with its routes");
}

sub delInternalIP {
	my $self = shift;
	my %args = @_;
	# arguments checking
	if (! exists $args{ipv4_internal_id} or ! defined $args{ipv4_internal_id}) { 
		$errmsg = "NetworkManager->delInternalIP need a ipv4_internal_id named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	
	# getting the row	
	my $row = $self->{db}->resultset('Ipv4Internal')->find( $args{ipv4_internal_id} );
	if(! defined $row) {
		$errmsg = "NetworkManager->delInternalIP : ipv4_internal_id $args{ipv4_internal_id} not found!";
		$log->error($errmsg);
		throw Kanopya::Exception::DB(error => $errmsg);
	}
	
	
	# related routes are automatically deleted due to foreign key 
	$row->delete;
	$log->info("Internal ip ($args{ipv4_internal_id}) deleted");
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
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	
	my $row = $self->{db}->resultset('Ipv4Public')->find($args{publicip_id});
	# getting public ip row
	if(! defined $row) {
		$errmsg = "NetworkManager->setClusterPublicIP : publicip_id $args{publicip_id} not found!";
		$log->error($errmsg);
		throw Kanopya::Exception::DB(error => $errmsg);
	}
	# try to set cluster_id to this ip
	eval {
		$row->set_column('cluster_id', $args{cluster_id});
		$row->update;
	};
	if($@) { 
		$errmsg = "NetworkManager->setClusterPublicIP : $@";
		$log->error($errmsg);
		throw Kanopya::Exception::DB(error => $errmsg);
	}
	$log->info("Public ip $args{publicip_id} set to cluster $args{cluster_id}");
}

=head2 unsetClusterPublicIP

associate public ip and cluster
	args:	publicip_id, cluster_id 
	
=cut

sub unsetClusterPublicIP {
	my $self = shift;
	my %args = @_;
	if (! exists $args{publicip_id} or ! defined $args{publicip_id} ||
		! exists $args{cluster_id} or ! defined $args{cluster_id}) { 
		$errmsg = "NetworkManager->unsetClusterPublicIP need publicip_id and cluster_id named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	
	my $row = $self->{db}->resultset('Ipv4Public')->find($args{publicip_id});
	# getting public ip row
	if(! defined $row) {
		$errmsg = "NetworkManager->unsetClusterPublicIP : publicip_id $args{publicip_id} not found!";
		$log->error($errmsg);
		throw Kanopya::Exception::DB(error => $errmsg);
	}
	if($row->get_column('cluster_id') ne $args{cluster_id}) {
		$errmsg = "NetworkManager->unsetClusterPublicIP : publicip_id $args{publicip_id} not set to cluster_id $args{cluster_id}!";
		$log->error($errmsg);
		throw Kanopya::Exception::DB(error => $errmsg);
	}
	
	# try to unset cluster_id to this ip
	eval {
		$row->set_column('cluster_id', undef);
		$row->update;
	};
	if($@) { 
		$errmsg = "NetworkManager->unsetClusterPublicIP : $@";
		$log->error($errmsg);
		throw Kanopya::Exception::DB(error => $errmsg);
	}
	$log->info("Public ip $args{publicip_id} unset to cluster $args{cluster_id}");
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
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	
	my $row = $self->{db}->resultset('Ipv4Route')->find($args{route_id});
	if(not defined $row) {
		$errmsg = "NetworkManager->delRoute : route_id $args{route_id} not found!";
		$log->error($errmsg);
		throw Kanopya::Exception::DB(error => $errmsg);
	}
	$row->delete;
	$log->info("route ($args{route_id}) successfully deleted");	
}

sub setClusterRoute {
    my $self = shift;
	my %args = @_;
	if (! exists $args{ipv4_route_id} or ! defined $args{ipv4_route_id} ||
		! exists $args{cluster_id} or ! defined $args{cluster_id}) { 
		$errmsg = "NetworkManager->setClusterRoute need ipv4_route_id and cluster_id named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	
#	my $row = $self->{db}->resultset('ClusterIpv4Route')->search({cluster_id => $args{cluster_id}, ipv4_route_id =>$args{ipv4_route_id}});
#	# getting public ip row
#	if(! defined $row) {
#		$errmsg = "NetworkManager->setClusterRoute : ipv4_route_id $args{ipv4_route_id} not found!";
#		$log->error($errmsg);
#		throw Kanopya::Exception::DB(error => $errmsg);
#	}
	# try to set cluster_id to this ip
	eval {
	    my $row = {cluster_id => $args{cluster_id}, ipv4_route_id =>$args{ipv4_route_id}};
		$self->{db}->resultset('ClusterIpv4Route')->create($row);
	};
	if($@) { 
		$errmsg = "NetworkManager->setClusterRoute : $@";
		$log->error($errmsg);
		throw Kanopya::Exception::DB(error => $errmsg);
	}
	$log->info("Route $args{ipv4_route_id} set to cluster $args{cluster_id}");
}

=head getRoutes

return list of registered routes

=cut

sub getRoutes {
	my $self = shift;
	my $routes = $self->{db}->resultset('Ipv4Route');
	my $routearray = [];
	while(my $r = $routes->next) {
		push @$routearray, {
			route_id => $r->get_column('ipv4_route_id'),
			ip_destination => $r->get_column('ipv4_route_destination'),
			gateway =>$r->get_column('ipv4_route_gateway'),
			context =>$r->get_column('ipv4_route_context')
		};
	}
	return $routearray;
}
1;