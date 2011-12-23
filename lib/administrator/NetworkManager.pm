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
use General;
use String::Random 'random_regex';

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
    
    General::checkParams(args => \%args, required => ['schemas', 'internalnetwork', 'dmznetwork']);
    
    $self->{db} = $args{schemas};
    $self->{internalnetwork} = $args{internalnetwork};
    $self->{dmznetwork} = $args{dmznetwork};
    bless $self, $class;
    $log->info("New Network Manager Loaded");
    return $self;
}

sub getInternalNetwork {
    my $self = shift;
    
#    if (wantarray){
#        return ($self->{internalnetwork}->{ip}, $self->{internalnetwork}->{mask});
#    }else {
#        # TOO BAD
    $log->error("####################################\n");
    $log->error("####################################\n");
    $log->error("Internal Network ". $self->{internalnetwork}->{ip} . "/24");
     return $self->{internalnetwork}->{ip} . "/24";
#    }
}

=head2 addRoute

add new route to a public ip given its id
    args: 
        public_ip_id : String : Public ip identifier
        ip_destination : String : network address, format : XXX.XXX.XXX.XXX/XX
        gateway    : String : gateway ip address
=cut

sub addRoute {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['publicip_id', 'ip_destination', 'gateway', 'context']);
    
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

=head2 getFreeIP

return the first unused ip address in a network

=cut

sub getFreeIP{
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['type']);
    my $type = $args{type};
    my $uppertype = ucfirst $args{type};
    # retrieve internal network from config
    my $network = new NetAddr::IP(
        $self->{$type."network"}->{ip},
        $self->{$type."network"}->{mask},
    );

    my ($i, $row, $freeip) = 0;
    
    # try to find a matching host of each ip of our network    
    while ($freeip = $network->nth($i)) {
        $row = $self->{db}->resultset("Ipv4".$uppertype)->find({ "ipv4_".$type ."_address" => $freeip->addr });
        
        # if no record is found for this ip address, it is free so we return it
        if(not defined $row) { 
                return $freeip->addr; }
        $log->debug($freeip->addr." is already used");
        $i++;
    }
    if(not defined $freeip) {
        $errmsg = "NetworkManager->getFree".$type."IP : all ip $type addresses seems to be used !";
        $log->error($errmsg);
        throw Kanopya::Exception::Network(error => $errmsg);
    }
}

=head2 getFreeInternalIP

return the first unused ip address in the internal network

=cut

sub getFreeInternalIP{
    my $self = shift;
    # retrieve internal network from config
#    my $network = new NetAddr::IP(
#        $self->{internalnetwork}->{ip},
#        $self->{internalnetwork}->{mask},
#    );
#    
#    my ($i, $row, $freeip) = 0;
#    
#    # try to find a matching host of each ip of our network    
#    while ($freeip = $network->nth($i)) {
#        $row = $self->{db}->resultset('Ipv4Internal')->find({ ipv4_internal_address => $freeip->addr });
#        
#        # if no record is found for this ip address, it is free so we return it
#        if(not defined $row) { 
#                return $freeip->addr; }
#        $log->debug($freeip->addr." is already used");
#        $i++;
#    }
#    if(not defined $freeip) {
#        $errmsg = "NetworkManager->getFreeInternalIP : all internal ip addresses seems to be used !";
#        $log->error($errmsg);
#        throw Kanopya::Exception::Network(error => $errmsg);
#    }
    $self->getFreeIP (type=>"internal");
}

=head2 getFreeDmzIP

return the first unused ip address in the dmz network

=cut

sub getFreeDmzIP{
    my $self = shift;
    $self->getFreeIP (type=>"dmz");
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
    
    General::checkParams(args => \%args, required => ['ip_address', 'ip_mask']);
    
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
    
    General::checkParams(args => \%args, required => ['ipv4_internal_address']);

    my $internal_ip_row = $self->{db}->resultset('Ipv4Internal')->find({ipv4_internal_address => $args{ipv4_internal_address},key=>"ipv4_internal_address_UNIQUE"});
    if (! defined $internal_ip_row){
        $errmsg = "NetworkManager->getInternalIPId address $args{ipv4_internal_address} was not found";
        $log->error($errmsg);
        throw Kanopya::Exception::DB(error => $errmsg);
    }
    return $internal_ip_row->get_column("ipv4_internal_id");
}

sub getDmzIPId{
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['ipv4_dmz_address']);

    my $internal_ip_row = $self->{db}->resultset('Ipv4Dmz')->find({ipv4_dmz_address => $args{ipv4_dmz_address},key=>"ipv4_dmz_address_UNIQUE"});
    if (! defined $internal_ip_row){
        $errmsg = "NetworkManager->getDmzIPId address $args{ipv4_dmz_address} was not found";
        $log->error($errmsg);
        throw Kanopya::Exception::DB(error => $errmsg);
    }
    return $internal_ip_row->get_column("ipv4_dmz_id");
}

sub getInternalIP{
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['ipv4_internal_id']);

    my %internal_ip_row = $self->{db}->resultset('Ipv4Internal')->find($args{ipv4_internal_id})->get_columns();
    return \%internal_ip_row;
}

sub getDmzIP{
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['ipv4_dmz_id']);

    my %dmz_ip_row = $self->{db}->resultset('Ipv4Dmz')->find($args{ipv4_dmz_id})->get_columns();
    return \%dmz_ip_row;
}

sub newIP {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['ipv4_address','ipv4_mask', 'type']);
    my $type = $args{type};
    my $uppertype = ucfirst($args{type});
    
    my $ip = new NetAddr::IP($args{ipv4_address}, $args{ipv4_mask});
    if(not defined $ip) { 
        $errmsg = "NetworkManager->newIP : wrong value for ip_address/ip_mask!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    } 
    
    my $gateway;
    if(exists $args{ipv4_default_gw} and defined $args{ipv4_default_gw}) {
        $gateway = new NetAddr::IP($args{ipv4_default_gw});
        if(not defined $gateway) {
            $errmsg = "NetworkManager->newIP : wrong value for gateway!";
            $log->error($errmsg);
            throw Kanopya::Exception::Internal(error => $errmsg);
        }
    }

    my $res;    
    # try to save public ip
    eval {
        my $row = {"ipv4_".$type."_address" => $ip->addr, "ipv4_".$type."_mask" => $ip->mask};
        if($gateway) { $row->{"ipv4_" .$type."internal_default_gw"} = $gateway->addr; }
        $res = $self->{db}->resultset("Ipv4$uppertype")->create($row);
        $log->debug("$type ip create and return ". $res->get_column("ipv4_".$type."_id"));
    };
    if($@) { 
        $errmsg = "NetworkManager->new$type"."IP: $@";
        $log->error($errmsg);
        throw Kanopya::Exception::DB(error => $errmsg); }
    $log->debug("new $type ip created");
    return $res->get_column("ipv4_".$type."_id");
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
    
    General::checkParams(args => \%args, required => ['ipv4_address','ipv4_mask']);

#    # ip format valid ?
#    my $internalip = new NetAddr::IP($args{ipv4_internal_address}, $args{ipv4_internal_mask});
#    if(not defined $internalip) { 
#        $errmsg = "NetworkManager->newInternalIP : wrong value for ip_address/ip_mask!";
#        $log->error($errmsg);
#        throw Kanopya::Exception::Internal(error => $errmsg);
#    } 
#    
#    my $gateway;
#    if(exists $args{ipv4_internal_default_gw} and defined $args{ipv4_internal_default_gw}) {
#        $gateway = new NetAddr::IP($args{ipv4_internal_default_gw});
#        if(not defined $gateway) {
#            $errmsg = "NetworkManager->newInternalIP : wrong value for gateway!";
#            $log->error($errmsg);
#            throw Kanopya::Exception::Internal(error => $errmsg);
#        }
#    }
#
#    my $res;    
#    # try to save public ip
#    eval {
#        my $row = {ipv4_internal_address => $internalip->addr, ipv4_internal_mask => $internalip->mask};
#        if($gateway) { $row->{ipv4_internal_default_gw} = $gateway->addr; }
#        $res = $self->{db}->resultset('Ipv4Internal')->create($row);
#        $log->debug("Public ip create and return ". $res->get_column("ipv4_internal_id"));
#    };
#    if($@) { 
#        $errmsg = "NetworkManager->newInternalIP: $@";
#        $log->error($errmsg);
#        throw Kanopya::Exception::DB(error => $errmsg); }
#    $log->debug("new internal ip created");
#    return $res->get_column("ipv4_internal_id");
    $args{type} = "internal";
    return $self->newIP(%args)
}

=head2 newDmzIP

add a new dmz ip address
    args: 
        ip_address
        ip_mask
    optional args:
        gateway
=cut

sub newDmzIP {
    #################################
    #TODO This method
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['ipv4_address','ipv4_mask']);
    $args{type} = "dmz";
    return $self->newIP(%args)
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
    
    General::checkParams(args => \%args, required => ['publicip_id']);
    
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

sub delIP {
    my $self = shift;
    my %args = @_;
    # arguments checking
    
    General::checkParams(args => \%args, required => ['ipv4_id', 'type']);
    my $type = $args{type};
    my $uppertype = ucfirst($args{type});

    # getting the row    
    my $row = $self->{db}->resultset("Ipv4".$uppertype)->find( $args{ipv4_id} );
    if(! defined $row) {
        $errmsg = "NetworkManager->del".$type."IP : ipv4_".$type."_id $args{ipv4_id} not found!";
        $log->error($errmsg);
        throw Kanopya::Exception::DB(error => $errmsg);
    }
    # related routes are automatically deleted due to foreign key 
    $row->delete;
    $log->info("$uppertype ip ($args{ipv4_id}) deleted");
}

sub delInternalIP {
    my $self = shift;
    my %args = @_;
    # arguments checking
    
    General::checkParams(args => \%args, required => ['ipv4_id']);
    
    $args{type} = "internal";
    $self->delIP(%args);
}

sub delDmzIP {
    my $self = shift;
    my %args = @_;
    # arguments checking
    
    General::checkParams(args => \%args, required => ['ipv4_id']);
    $args{type} = "dmz";
    $self->delIP(%args);

}

=head2 setClusterPublicIP

associate public ip and cluster
    args:    publicip_id, cluster_id 
    

=cut

sub setClusterPublicIP {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['publicip_id', 'cluster_id']);
    
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

=head2 setTierDmzIP

associate dmz ip and tier
    args:    dmzip_id, tier_id 
    

=cut

sub setTierDmzIP {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['dmzip_id', 'tier_id']);
    
    my $row = $self->{db}->resultset('Ipv4Dmz')->find($args{dmzip_id});
    # getting public ip row
    if(! defined $row) {
        $errmsg = "NetworkManager->setTierDmzIP : dmzip_id $args{dmzip_id} not found!";
        $log->error($errmsg);
        throw Kanopya::Exception::DB(error => $errmsg);
    }
    # try to set cluster_id to this ip
    eval {
        $row->set_column('tier_id', $args{tier_id});
        $row->update;
    };
    if($@) { 
        $errmsg = "NetworkManager->setTierDmzIP : $@";
        $log->error($errmsg);
        throw Kanopya::Exception::DB(error => $errmsg);
    }
    $log->info("Public ip $args{dmzip_id} set to cluster $args{tier_id}");
}

=head2 unsetClusterPublicIP

associate public ip and cluster
    args:    publicip_id, cluster_id 
    
=cut

sub unsetClusterPublicIP {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['publicip_id','cluster_id']);
    
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
    
    General::checkParams(args => \%args, required => ['route_id']);
    
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
    
    General::checkParams(args => \%args, required => ['ipv4_route_id','cluster_id']);
    
#    my $row = $self->{db}->resultset('ClusterIpv4Route')->search({cluster_id => $args{cluster_id}, ipv4_route_id =>$args{ipv4_route_id}});
#    # getting public ip row
#    if(! defined $row) {
#        $errmsg = "NetworkManager->setClusterRoute : ipv4_route_id $args{ipv4_route_id} not found!";
#        $log->error($errmsg);
#        throw Kanopya::Exception::DB(error => $errmsg);
#    }
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

=head generateMacAddress

return a mac address auto generated and not used by any host

=cut

sub generateMacAddress {
	my $self = shift;
	my $macaddress;
	my @hosts = ();
	my $regexp = '[a-f0-9]{2}:[a-f0-9]{2}:[a-f0-9]{2}:[a-f0-9]{2}:[a-f0-9]{2}:[a-f0-9]{2}';  
	do {
		$macaddress = random_regex($regexp);
		@hosts = $self->{db}->resultset('Host')->search(
			{ host_mac_address => $macaddress },
			{ rows => 1 }
		);
	} while( scalar(@hosts) );
	return $macaddress;
}

1;
