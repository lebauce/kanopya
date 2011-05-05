# StateManager.pm - Object class of State Manager server

# Copyright (C) 2009, 2010, 2011, 2012, 2013
#   Free Software Foundation, Inc.

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


=head1 NAME

<StateManager> – <StateManager main class>

=head1 VERSION

This documentation refers to <StateManager> version 1.0.0.

=head1 SYNOPSIS

use <Executor>;


=head1 DESCRIPTION

StateManager is the main module to manage state

=head1 METHODS

=cut

package StateManager;

use strict;
use warnings;


use General;
use Kanopya::Exceptions;
use Operation;
use EFactory;
use Administrator;
use Entity::Cluster;
use Entity::Motherboard;

use XML::Simple;
use Data::Dumper;
use Log::Log4perl "get_logger";
our $VERSION = '1.00';

use Net::Ping;
use IO::Socket;

my $errmsg;
my $log = get_logger("statemanager");


=head2 new

    my $executor = Executor->new();

Executor::new creates a new executor object.

=cut

sub new {
    my $class = shift;
    my $self = {};

    bless $self, $class;
        
   $self->_init();
    
    # Plus tard rajouter autre chose
    return $self;
}

=head2 _init

Executor::_init is a private method used to define internal parameters.

=cut

sub _init {
	my $self = shift;
	
	$self->{config} = XMLin("/opt/kanopya/conf/executor.conf");
	if ((! exists $self->{config}->{user}->{name} ||
		 ! defined exists $self->{config}->{user}->{name}) &&
		(! exists $self->{config}->{user}->{password} ||
		 ! defined exists $self->{config}->{user}->{password})){ 
		throw Kanopya::Exception::Internal::IncorrectParam(error => "StateManager->new need user definition in config file!"); }
	my $adm = Administrator::authenticate(login => $self->{config}->{user}->{name},
								 password => $self->{config}->{user}->{password});
	return;
}

sub checkNodeUp {
    my %args = @_;
    
    if ((!defined $args{cluster} or !exists $args{cluster})||
        (!defined $args{motherboard} or !exists $args{motherboard}) ||
        (!defined $args{executor_ip} or !exists $args{executor_ip})){
            $errmsg = "StateManager::updateNodeStatus need a cluster and motherboard named argument!";	
		    $log->error($errmsg);
		    throw Kanopya::Exception::Internal(error => $errmsg);
    }
    
    if ($args{motherboard}->getAttr(name => "motherboard_state") ne "up"){
        return 0;
    }
   
    my $components= $args{cluster}->getComponents(category => "all");
    my $protoToTest;
    my $node_available = 1;
    my $host_econtext;

    my $node_ip = $args{motherboard}->getInternalIP()->{ipv4_internal_address};
    if (!$node_ip) {
        $errmsg = "Node without IP!";	
        $log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
    }
    eval {
        $host_econtext = EFactory::newEContext(ip_source => $args{executor_ip}, ip_destination => $node_ip);};
    if ($@) {
        return 0;
    }
   	foreach my $i (keys %$components) {
   	    print "\tBrowse component : " .$components->{$i}->getComponentAttr()->{component_name}."\n";
   	    my $tmp_ecomp = EFactory::newEEntity(data => $components->{$i});
   	    if (!$tmp_ecomp->isUp(host=>$args{motherboard}, cluster=>$args{cluster}, host_econtext => $host_econtext)) {
   	        return 0;
   	    }
	}

    return $node_available;
}



=head2 run

Executor->run() run the executor server.

=cut

sub run {
	my $self = shift;
	my $running = shift;
	
	my $adm = Administrator->new();
	$adm->addMessage(from => 'Executor', level => 'info', content => "Kanopya State Manager started.");
   	while ($$running) {
        # First Check Motherboard Status
        my @motherboards = Entity::Motherboard->getMotherboards(hash => {motherboard_state => {'!=','down'}});
#   	    my @moth_index = keys %$motherboards;
		foreach my $mb (@motherboards) {
			eval {
		  		my $emotherboard = EFactory::newEEntity(data => $mb);
	      		my $is_up = $emotherboard->checkUp();
		  		updateMotherboardStatus(pingable => $is_up, motherboard=>$mb);
		  	};
		  	if($@) {
		  		my $exception = $@;
		  		$adm->addMessage(from => 'State-manager', level => 'error', content => $exception);
   				$log->error($exception);
		  	}
   	    }


   	    my @clusters = Entity::Cluster->getClusters(hash=>{cluster_state => {'!=' => 'down'}});
   	    foreach my $cluster (@clusters) {
            
            # Second Check node status
   	        $log->debug("cluster get is <" . $cluster->getAttr(name=>'cluster_name'). ">\n");
   	        my $motherboards = $cluster->getMotherboards();
   	        my @moth_index = keys %$motherboards;
   	        foreach my $mb (@moth_index) {
		        eval {
		        	my $srv_available = checkNodeUp(motherboard=>$motherboards->{$mb}, 
		        	                                cluster=>$cluster,
		        	                                executor_ip=>Entity::Cluster->get(id => $self->{config}->{cluster}->{executor})->getMasterNodeIp());
		        	updateNodeStatus(motherboard=>$motherboards->{$mb}, services_available => $srv_available, cluster => $cluster);
		        };
		        if($@) {
		            my $exception = $@;
		            $adm->addMessage(from => 'State-manager', level => 'error', content => $exception);
		            $log->error($exception);
		        }
   	        }
   	        eval {
   	        updateClusterStatus(motherboards=>$motherboards,cluster=>$cluster);};
		        if($@) {
		            my $exception = $@;
		            $adm->addMessage(from => 'State-manager', level => 'error', content => $exception);
		            $log->error($exception);
		        }
   	    }
   	    
   		sleep 10;
   	}

   	$log->debug("condition become false : $$running"); 
   	$adm->addMessage(from => 'Executor', level => 'warning', content => "Kanopya State Manager stopped");
}

################################### MOTHERBOARD STATES METHOD PART
sub motherboardBroken{
    my %args = @_;
    if ((!defined $args{motherboard} or !exists $args{motherboard})){
            $errmsg = "StateManager::motherboardBroken need a motherboard named argument!";	
		    $log->error($errmsg);
		    throw Kanopya::Exception::Internal(error => $errmsg);
    }
    my $mb_mac = $args{motherboard}->getAttr(name=>"motherboard_mac_address");
    print "motherboard". $mb_mac." broken\n";
    my $adm = Administrator->new();
	$adm->addMessage(from => 'State-manager', level => 'info', content => "Motherboard with mac address <$mb_mac> is now broken");
    $args{motherboard}->setAttr(name=>"motherboard_state", value => "broken:".time);
    $args{motherboard}->save();
}

sub motherboardRepaired{
    my %args = @_;
    if ((!defined $args{motherboard} or !exists $args{motherboard})){
            $errmsg = "StateManager::motherboardBroken need a motherboard named argument!";	
		    $log->error($errmsg);
		    
		    throw Kanopya::Exception::Internal(error => $errmsg);
        }
    $args{motherboard}->setAttr(name=>"motherboard_state", value => "up");
    $args{motherboard}->save();
}

sub motherboardStopped{
    my %args = @_;
    if ((!defined $args{motherboard} or !exists $args{motherboard})){
            $errmsg = "StateManager::motherboardStopped need a motherboard named argument!";	
		    $log->error($errmsg);
		    throw Kanopya::Exception::Internal(error => $errmsg);
        }
    $args{motherboard}->setAttr(name=>"motherboard_state", value => "down");
    $args{motherboard}->save();
    my %params;
    $params{cluster_id} = $args{motherboard}->getClusterId();
    $params{motherboard_id} = $args{motherboard}->getAttr(name=>"motherboard_id");
    Operation->enqueue(priority => 200,
                   type     => 'PostStopNode',
                   params   => \%params);
}

sub motherboardStarted{
    my %args = @_;
    if ((!defined $args{motherboard} or !exists $args{motherboard})){
            $errmsg = "StateManager::motherboardStarted need a motherboard named argument!";	
		    $log->error($errmsg);
		    throw Kanopya::Exception::Internal(error => $errmsg);
        }
    $args{motherboard}->setAttr(name=>"motherboard_state", value => "up");
    $args{motherboard}->save();
    my %params;
    $params{cluster_id} = $args{motherboard}->getClusterId();
    $params{motherboard_id} = $args{motherboard}->getAttr(name=>"motherboard_id");
    
    Operation->enqueue(priority => 200,
                   type     => 'PostStartNode',
                   params   => \%params);
}

################################### NODE STATES METHOD PART

sub nodeBroken{
    my %args = @_;
    if ((!defined $args{motherboard} or !exists $args{motherboard})){
            $errmsg = "StateManager::nodeBroken need a motherboard named argument!";	
		    $log->error($errmsg);
		    throw Kanopya::Exception::Internal(error => $errmsg);
        }
    print "motherboard". $args{motherboard}->getAttr(name=>"motherboard_mac_address")." broken\n";
    $args{motherboard}->setNodeState(state => "broken:".time);
}

sub nodeRepaired{
    my %args = @_;
    if ((!defined $args{motherboard} or !exists $args{motherboard})){
            $errmsg = "StateManager::nodeRepaired need a motherboard named argument!";	
		    $log->error($errmsg);
		    throw Kanopya::Exception::Internal(error => $errmsg);
        }
    $args{motherboard}->setNodeState(state => "in");
}

sub nodeOut{
    my %args = @_;
    if ((!defined $args{motherboard} or !exists $args{motherboard})){
            $errmsg = "StateManager::nodeOut need a motherboard named argument!";	
		    $log->error($errmsg);
		    throw Kanopya::Exception::Internal(error => $errmsg);
    }
}

sub nodeIn {
    my %args = @_;
    if ((!defined $args{motherboard} or !exists $args{motherboard})){
            $errmsg = "StateManager::nodeIn need a motherboard named argument!";	
		    $log->error($errmsg);
		    throw Kanopya::Exception::Internal(error => $errmsg);
        }
    $args{motherboard}->setNodeState(state => "in");

}

############################# ERROR STATES VALUES

sub incorrectMotherboard {
    my %args = @_;
    if ((!defined $args{motherboard} or !exists $args{motherboard})){
            $errmsg = "StateManager::incorrectMotherboard need a motherboard named argument!";	
		    $log->error($errmsg);
		    throw Kanopya::Exception::Internal(error => $errmsg);
        }
    my $error = "Wrong motherboard <". $args{motherboard}->getAttr(name=>'motherboard_mac_address')."> must not be in cluster";
    throw Kanopya::Exception::Internal(error => $error);
}

sub incorrectStates {
    my %args = @_;
    if ((!defined $args{motherboard} or !exists $args{motherboard})||
        ((!defined $args{services_available} or !exists $args{services_available})&&
         (!defined $args{pingable} or !exists $args{pingable}))){
            $errmsg = "StateManager::incorrectStates need a motherboard and (pingable or services_available) named argument!";	
		    $log->error($errmsg);
		    throw Kanopya::Exception::Internal(error => $errmsg);
        }
    my $state = $args{pingable} || $args{services_available};
    my $error = "Wrong state <$state> for motherboard <". $args{motherboard}->getAttr(name=>'motherboard_mac_address').">\n";
    throw Kanopya::Exception::Internal(error => $error);
}

sub testPreGoingInNode {
    my %args = @_;
    
    if ((!defined $args{cluster} or !exists $args{cluster})||
        (!defined $args{motherboard} or !exists $args{motherboard})){
            $errmsg = "StateManager::testPreGoingInNode need a cluster and motherboard named argument!";	
		    $log->error($errmsg);
		    throw Kanopya::Exception::Internal(error => $errmsg);
    }
    my $components= $args{cluster}->getComponents(category => "all");
    my $protoToTest;
    my $cluster_ready = 1;

   	foreach my $i (keys %$components) {
   	    if ($cluster_ready){
        $cluster_ready = $components->{$i}->readyNodeAddition(motherboard_id => $args{motherboard}->getAttr(name => "motherboard_id"));}
   	    $log->debug("Test if ready for node addition and now ready is <$cluster_ready>");
	}

    if ($cluster_ready) {
    $log->debug("StateManager::testPreGoingInNode before enqueueing Startnode with motherboard_id <" .
                $args{motherboard}->getAttr(name=>'motherboard_id')."> and cluster_id <" .
                $args{cluster}->getAttr(name=>'cluster_id').">");
	Operation->enqueue(
    	priority => 200,
        type     => 'StartNode',
        params   => {cluster_id => $args{cluster}->getAttr(name=>'cluster_id'),
                     motherboard_id => $args{motherboard}->getAttr(name=>'motherboard_id')});
    }
}

sub testPreGoingOutNode {
    my %args = @_;
    
    if ((!defined $args{cluster} or !exists $args{cluster})||
        (!defined $args{motherboard} or !exists $args{motherboard})){
            $errmsg = "StateManager::testPreGoingOutNode need a cluster and motherboard named argument!";	
		    $log->error($errmsg);
		    throw Kanopya::Exception::Internal(error => $errmsg);
    }
    my $components= $args{cluster}->getComponents(category => "all");
    my $protoToTest;
    my $cluster_ready = 1;

   	foreach my $i (keys %$components) {
        $cluster_ready = $components->{$i}->readyNodeRemoving(motherboard_id => $args{motherboard}->getAttr(name => "motherboard_id")) && $cluster_ready;
   	    $log->debug("Test if ready for node addition and now ready is <$cluster_ready>");
	}

    if ($cluster_ready) {
    $log->debug("StateManager::testPreGoingOutNode before enqueueing StopNode with motherboard_id <" .
                $args{motherboard}->getAttr(name=>'motherboard_id')."> and cluster_id <" .
                $args{cluster}->getAttr(name=>'cluster_id').">");
	Operation->enqueue(
    	priority => 200,
        type     => 'StopNode',
        params   => {cluster_id => $args{cluster}->getAttr(name=>'cluster_id'),
                     motherboard_id => $args{motherboard}->getAttr(name=>'motherboard_id')},
                     );
    }
}

sub testGoingInNode {
    #TODO Test how long node going in cluster
}
sub testGoingOutNode {
    #TODO Test how long node going out cluster
}

sub testStartingMotherboard{
    # Motherboard is Starting and is unpingable
    #TODO Test how long motherboard starting
}


sub testStoppingMotherboard{
    #If node is in
    # Foreach component TestReadytoBeRemoved
    #TODO Test how long motherboard starting
}
######################## UPDATE METHOD

sub updateMotherboardStatus {
    my %args = @_;
    if ((!defined $args{pingable} or !exists $args{pingable})||
        (!defined $args{motherboard} or !exists $args{motherboard})){
            $errmsg = "StateManager::updateMotherboardStatus need a pingable and motherboard named argument!";	
		    $log->error($errmsg);
		    throw Kanopya::Exception::Internal(error => $errmsg);
        }
    my %actions = (0 => { up        => \&motherboardBroken,
                          starting  => \&testStartingMotherboard,
                          broken    => sub {},
                          stopping  => \&motherboardStopped},
                   1 => { broken    => \&motherboardRepaired,
                          up        => sub {},
                          starting  => \&motherboardStarted,
                          stopping  => \&testStoppingMotherboard});
   
   my $state = $args{motherboard}->getAttr(name=>"motherboard_state");
   my @tmp = split /:/, $state;
   $state = $tmp[0];
   print "UpdateMotherboardStatus state is $state for motherboard" . $args{motherboard}->getAttr(name=>"motherboard_mac_address") . "\n";
   my $method = $actions{$args{pingable}}->{$state} || \&incorrectStates;
    $method->(pingable=>$args{pingable},motherboard=>$args{motherboard},begin_time => $tmp[1]);   
}



sub updateClusterStatus {
    my %args = @_;
    General::checkParams(\%args, ['cluster','motherboards']);
    my $adm = Administrator->new();
    my $motherboards = $args{motherboards};
    # third Check Cluster Status
    my @cluster_state = split /:/, $args{cluster}->getAttr(name=>"cluster_state");
    my $master_id = $args{cluster}->getMasterNodeId();
    $log->debug("Cluster status update for cluster <". $args{cluster}->getAttr(name=>'cluster_name'). "> with master_node <$master_id> and state <$cluster_state[0]>\n");
    if ( $cluster_state[0] eq "starting"){
        if ($master_id){
            if ((scalar keys %$motherboards) < $args{cluster}->getAttr(name => "cluster_min_node")){
                $log->info("Cluster Starting, master node is ok, there are less node than min node");
                my %params = (cluster_id => $args{cluster}->getAttr(name =>"cluster_id"));
                eval {
                    $log->debug("New Operation PreStartNode with attrs : " . %params);
                    Operation->enqueue(
                                       priority => 200,
                                       type     => 'PreStartNode',
                                       params   => \%params);};
               if ($@){
                   my $error = $@;
                   if ($error->isa('Kanopya::Exception::OperationAlreadyEnqueued')) {
                       $log->info("PreStartNode operation is already enqueued");
                   }
               }
            } else {
                $adm->addMessage(from => 'State-manger', level => 'info', content => "Cluster <".$args{cluster}->getAttr(name=>"cluster_name").">. is now up !");
                $log->info("Cluster <".$args{cluster}->getAttr(name=>"cluster_name").">. is now up !");
   	            $args{cluster}->setAttr(name=>"cluster_state", value => "up");
   	            $args{cluster}->save();
            }
        }
        else {
            # Test if addNode process is already enqueued
            
        }
    }
    if (($cluster_state[0] eq "stopping")){
        if (!scalar keys %$motherboards){
            $adm->addMessage(from => 'State-manger', level => 'info', content => "Cluster <".$args{cluster}->getAttr(name=>"cluster_name").">. is now down !");
            $log->info("Cluster <".$args{cluster}->getAttr(name=>"cluster_name").">. is now down !");
   	        $args{cluster}->setAttr(name=>"cluster_state", value => "down");
   	        $args{cluster}->save();
        }
# A case is not managed, when master_node flag change of motherboard because of failover during cluster stopping
        if( scalar keys %$motherboards == 1){
   	        if (!$master_id){
   	           $errmsg = "Last node in cluster is not master node ! My god...";	
		       $log->error($errmsg);
		      throw Kanopya::Exception::Internal(error => $errmsg);
            }
            if ($motherboards->{$master_id}->getNodeState() eq "up"){
   	            my %params = (cluster_id => $args{cluster}->getAttr(name =>"cluster_id"),
                              motherboard_id => $master_id);
                $log->debug("New Operation PreStopNode with attrs : " . %params);
                eval {
                    Operation->enqueue(
                                       priority => 200,
                                       type     => 'PreStopNode',
                                       params   => \%params);};
                if ($@){
                    my $error = $@;
                    if ($error->isa('Kanopya::Exception::OperationAlreadyEnqueued')) {
                        $log->info("PreStopNode operation is already enqueued");}
                }
            }
        }
        else {
            my $motherboards = $args{cluster}->getMotherboards();
            my $mb_id;
            foreach my $mb (keys %$motherboards){
                if ($motherboards->{$mb} != $master_id){
                    $mb_id = $motherboards->{$mb}->getAttr(name=>'motherboard_id');
                }
            }
            my %params = (cluster_id => $args{cluster}->getAttr(name =>"cluster_id"),
                          motherboard_id => $mb_id);
            ############################################################################
            eval {
                Operation->enqueue(
    	                       priority => 200,
                               type     => 'PreStopNode',
                               params   => \%params);};
            if ($@){
                my $error = $@;
                if ($error->isa('Kanopya::Exception::OperationAlreadyEnqueued')) {
                    $log->info("PreStopNode operation is already enqueued");}
            }
        }
        
    }

}

sub updateNodeStatus {
    my %args = @_;
    if ((!defined $args{services_available} or !exists $args{services_available})||
        (!defined $args{motherboard} or !exists $args{motherboard}) ||
        (!defined $args{cluster} or !exists $args{cluster})){
            $errmsg = "StateManager::updateNodeStatus need a srv_available and motherboard named argument!";	
		    $log->error($errmsg);
		    throw Kanopya::Exception::Internal(error => $errmsg);
    }
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
   my $node_state = $args{motherboard}->getNodeState();
   my @tmp = split /:/, $node_state;
   $node_state = $tmp[0];
   print "Node state is $node_state and service status is $args{services_available}\n";
   my $method = $actions{$args{services_available}}->{$node_state} || \&incorrectStates;
   $method->(services_available=>$args{services_available},motherboard=>$args{motherboard}, cluster=>$args{cluster});
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
