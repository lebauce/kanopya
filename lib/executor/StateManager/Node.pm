# StateManager.pm - Object class of State Manager server

#    Copyright 2011 Hedera Technology SAS
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


=head1 NAME

<StateManager::Node>  <StateManager::Node main class>

=head1 VERSION

This documentation refers to <StateManager::Node> version 1.0.0.

=head1 SYNOPSIS

use <Executor>;


=head1 DESCRIPTION

StateManager::Node is the main module to manage state

=head1 METHODS

=cut

package StateManager::Node;

use strict;
use warnings;

use Message;
use General;
use Kanopya::Exceptions;
use Operation;
use EFactory;
use Administrator;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Host;

use XML::Simple;
use Data::Dumper;
use Log::Log4perl "get_logger";
our $VERSION = '1.00';

use Net::Ping;
use IO::Socket;

my $errmsg;
my $log = get_logger("statemanager");



sub checkNodeUp {
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['cluster', 'host', 'executor_ip']);
    my $adm = Administrator->new();
    if ($args{host}->getAttr(name => "host_state") !~ /^up:.*/){
        return 0;
    }

    my $components= $args{cluster}->getComponents(category => "all");
    my $protoToTest;
    my $node_available = 1;
    my $host_econtext;

    my $node_ip = $args{host}->getInternalIP()->{ipv4_internal_address};
    if (!$node_ip) {
        $errmsg = "Node without IP!";    
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    eval {
        $host_econtext = EFactory::newEContext(ip_source => $args{executor_ip}, ip_destination => $node_ip);
    };
    if ($@) {
        Message->send(from => 'StateManager', level => 'info', content => "Kanopya could not connect to node <"
                        .$args{host}->getAttr(name=>"host_hostname")."> with ip <"
                        . $node_ip ."> in cluster <".$args{cluster}->getAttr(name=>"cluster_name").">");
        return 0;
    }
    
    foreach my $i (keys %$components) {
        $log->debug("Browse component : " .$components->{$i}->getComponentAttr()->{component_name});
        my $tmp_ecomp = EFactory::newEEntity(data => $components->{$i});
        if (!$tmp_ecomp->isUp(host=>$args{host}, cluster=>$args{cluster}, host_econtext => $host_econtext)) {
            Message->send(from => 'StateManager', level => 'info', content => "Kanopya detects a component \""
            .$components->{$i}->getComponentAttr()->{component_name}."\" not available on node \""
            .$args{host}->getAttr(name=>"host_hostname")."\" with ip \""
            . $node_ip ."\" in cluster \"".$args{cluster}->getAttr(name=>"cluster_name")."\"");
            return 0;
        }
    }

    return $node_available;
}

################################### NODE STATES METHOD PART

sub nodeBroken{
    my %args = @_;
    General::checkParams(args => \%args, required => ['host']);
       
    $args{host}->setNodeState(state => 'broken');
    logNodeStateChange(
        ip_address => $args{host}->getInternalIP()->{ipv4_internal_address},
        newstatus => 'broken',
        level => 'warning'        
    );
}

sub nodeRepaired{
    my %args = @_;
    General::checkParams(args => \%args, required => ['host']);
    
    $args{host}->setNodeState(state => $args{host}->getPrevNodeState());
    logNodeStateChange(
        ip_address => $args{host}->getInternalIP()->{ipv4_internal_address},
        newstatus => 'in',
        level => 'info'        
    );
}

sub nodeOut{
    my %args = @_;
    # service are not available but host answer to ping,
    # states are stoping and goingout
    General::checkParams(args => \%args, required => ['host']);
    
    my %params;
    $params{cluster_id} = $args{host}->getClusterId();
    $params{host_id} = $args{host}->getAttr(name=>"host_id");
    Operation->enqueue(priority => 200,
                   type     => 'PostStopNode',
                   params   => \%params);
#    logNodeStateChange(
#        ip_address => $args{host}->getInternalIP()->{ipv4_internal_address},
#        newstatus => 'BAH LA JE SAIS PAS QUOI METTRE...',
#        level => 'info'        
#    );
}

sub nodeIn {
    my %args = @_;
    General::checkParams(args => \%args, required => ['host']);
    $args{host}->setNodeState(state => "in");
    logNodeStateChange(
        ip_address => $args{host}->getInternalIP()->{ipv4_internal_address},
        newstatus => 'in',
        level => 'info'        
    );

}

sub incorrectStates {
    my %args = @_;
    if ((!defined $args{host} or !exists $args{host})||
        ((!defined $args{services_available} or !exists $args{services_available})&&
         (!defined $args{pingable} or !exists $args{pingable}))){
            $errmsg = "StateManager::incorrectStates need a host and (pingable or services_available) named argument!";    
            $log->error($errmsg);
            throw Kanopya::Exception::Internal(error => $errmsg);
        }
    my $state = $args{pingable} || $args{services_available};
    my $error = "Wrong state <$state> for host <". $args{host}->getAttr(name=>'host_mac_address').">\n";
    throw Kanopya::Exception::Internal(error => $error);
}

sub testPreGoingInNode {
    my %args = @_;
    
    if ((!defined $args{cluster} or !exists $args{cluster})||
        (!defined $args{host} or !exists $args{host})){
            $errmsg = "StateManager::testPreGoingInNode need a cluster and host named argument!";    
            $log->error($errmsg);
            throw Kanopya::Exception::Internal(error => $errmsg);
    }
    my $components= $args{cluster}->getComponents(category => "all");
    my $protoToTest;
    my $cluster_ready = 1;

       foreach my $i (keys %$components) {
           if ($cluster_ready){
        $cluster_ready = $components->{$i}->readyNodeAddition(host_id => $args{host}->getAttr(name => "host_id"));}
           $log->debug("Test if ready for node addition and now ready is <$cluster_ready>");
    }

    if ($cluster_ready) {
    $log->debug("StateManager::testPreGoingInNode before enqueueing Startnode with host_id <" .
                $args{host}->getAttr(name=>'host_id')."> and cluster_id <" .
                $args{cluster}->getAttr(name=>'cluster_id').">");
    Operation->enqueue(
        priority => 200,
        type     => 'StartNode',
        params   => {cluster_id => $args{cluster}->getAttr(name=>'cluster_id'),
                     host_id => $args{host}->getAttr(name=>'host_id')});
    }
}

sub testPreGoingOutNode {
    my %args = @_;
    
    if ((!defined $args{cluster} or !exists $args{cluster})||
        (!defined $args{host} or !exists $args{host})){
            $errmsg = "StateManager::testPreGoingOutNode need a cluster and host named argument!";    
            $log->error($errmsg);
            throw Kanopya::Exception::Internal(error => $errmsg);
    }
    my $components= $args{cluster}->getComponents(category => "all");
    my $protoToTest;
    my $cluster_ready = 1;

       foreach my $i (keys %$components) {
        $cluster_ready = $components->{$i}->readyNodeRemoving(host_id => $args{host}->getAttr(name => "host_id")) && $cluster_ready;
           $log->debug("Test if ready for node addition and now ready is <$cluster_ready>");
    }

    if ($cluster_ready) {
    $log->debug("StateManager::testPreGoingOutNode before enqueueing StopNode with host_id <" .
                $args{host}->getAttr(name=>'host_id')."> and cluster_id <" .
                $args{cluster}->getAttr(name=>'cluster_id').">");
    Operation->enqueue(
        priority => 200,
        type     => 'StopNode',
        params   => {cluster_id => $args{cluster}->getAttr(name=>'cluster_id'),
                     host_id => $args{host}->getAttr(name=>'host_id')},
                     );
    }
}

sub testGoingInNode {
    #TODO Test how long node going in cluster
}
sub testGoingOutNode {
    #TODO Test how long node going out cluster
}


sub updateNodeStatus {
    my %args = @_;

    General::checkParams(args => \%args, required => ['host','cluster','services_available']);

    # state pregoingout is impossible when node is not available (it has to be repaired before)
    my %actions = (0 => { in        => \&nodeBroken,
                          goingin  => \&testGoingInNode,
                          pregoingin => \&testPreGoingInNode,
                          broken    => sub {},
                          goingout  => \&nodeOut,
                          pregoingout => \&testPreGoingOutNode},
                   # state PreGoingIn is not possible when node is available
                   1 => { broken    => \&nodeRepaired,
                          in        => sub {},
                          goingin  => \&nodeIn,
                          pregoingout => \&testPreGoingOutNode,
                          goingout  => \&testGoingOutNode});
   my $node_state = $args{host}->getNodeState();
   my @tmp = split(/:/, $node_state);
   $node_state = $tmp[0];
   print "Node state <$node_state> and service availability <$args{services_available}>\n";
   my $method = $actions{$args{services_available}}->{$node_state} || \&incorrectStates;
   $method->(services_available=>$args{services_available},host=>$args{host}, cluster=>$args{cluster});
}


sub logNodeStateChange {
    my %args = @_;
    General::checkParams(args => \%args, required => ['ip_address', 'newstatus', 'level']);
    my $adm = Administrator->new();
    my $msg = "Node with ip address $args{ip_address} is now $args{newstatus}";
    Message->send(from => 'StateManager', level => $args{level}, content => $msg);
    $log->info($msg); 
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
