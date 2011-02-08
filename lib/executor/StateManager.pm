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

use Log::Log4perl "get_logger";
our $VERSION = '1.00';
use General;
use Kanopya::Exceptions;
use XML::Simple;
use Administrator;
use Entity::Cluster;
use Entity::Motherboard;
use Data::Dumper;
use Operation;

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
        (!defined $args{motherboard} or !exists $args{motherboard})){
            $errmsg = "StateManager::updateNodeStatus need a cluster and motherboard named argument!";	
		    $log->error($errmsg);
		    throw Kanopya::Exception::Internal(error => $errmsg);
    }
    my $components= $args{cluster}->getComponents(category => "all");
    my $protoToTest;
    my $node_available = 1;    
    my $node_ip = $args{motherboard}->getAttr(name => 'motherboard_internal_ip');

   	foreach my $i (keys %$components) {
   	    print "Browse component : " .$components->{$i}->getComponentAttr()->{component_name}."\n";
		if ($components->{$i}->can("getNetConf")) {
		    my $protoToTest = $components->{$i}->getNetConf();
		    print "Component with a netConf, its proto is %$protoToTest \n";
            foreach my $j (keys %$protoToTest) {
                print "Test port <$j> of motherboard <$node_ip> with protocol <" . $protoToTest->{$j} ."> for component " . $components->{$i}->getComponentAttr()->{component_name} ."\n";
                my $sock = new
                        IO::Socket::INET(PeerAddr=>$node_ip,PeerPort=>$j,Proto=>$protoToTest->{$j});
                if(! $sock) {
                    $node_available = 0;
                    last; 
                }
                close $sock or die "close: $!";
            }
	   }
	}

    return $node_available;
}

sub checkMotherboardUp {
    my %args = @_;
    if ((!defined $args{ip} or !exists $args{ip})){
            $errmsg = "StateManager::checkMotherboardUp need an ip named argument!";	
		    $log->error($errmsg);
		    throw Kanopya::Exception::Internal(error => $errmsg);
    }
	my $p = Net::Ping->new();
	my $pingable = $p->ping($args{ip});
	$p->close();
	return $pingable;
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
   	    print "One another run into state manager\n";
   	    my @clusters = Entity::Cluster->getClusters(hash=>{cluster_state => 'Up'});
   	    print "First cluster get is <" . $clusters[0]->getAttr(name=>'cluster_name'). ">\n";
   	    foreach my $cluster (@clusters) {
   	    print "cluster get is <" . $cluster->getAttr(name=>'cluster_name'). ">\n";
   	        my $motherboards = $cluster->getMotherboards();
   	        my @moth_index = keys %$motherboards;
   	        foreach my $mb (@moth_index) {
				my $pingable = checkMotherboardUp(ip => $motherboards->{$mb}->getAttr( name => 'motherboard_internal_ip' ));
				print "Pingable : $pingable for motherboard ".$motherboards->{$mb}->getAttr( name => 'motherboard_internal_ip' ) ." state " . $motherboards->{$mb}->getAttr(name=>"motherboard_state")."\n";
		        updateMotherboardStatus(pingable => $pingable, motherboard=>$motherboards->{$mb});
		        my $srv_available = checkNodeUp(motherboard=>$motherboards->{$mb}, cluster=>$cluster);
		        updateNodeStatus(motherboard=>$motherboards->{$mb}, services_available => $srv_available);
   	        }
   	    }
   	    my @motherboards = Entity::Motherboard->getMotherboards(hash => {-or => [motherboard_state => {'like','starting%'},
   	                                                                             motherboard_state => {'like','stopping%'},
   	                                                                             motherboard_state => {'like','broken'}]});
#   	    my @moth_index = keys %$motherboards;
   	    foreach my $mb (@motherboards) {
		  my $pingable = checkMotherboardUp(ip => $mb->getAttr( name => 'motherboard_internal_ip' ));
		  updateMotherboardStatus(pingable => $pingable, motherboard=>$mb);
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
        print "motherboard". $args{motherboard}->getAttr(name=>"motherboard_mac_address")." broken\n";
    $args{motherboard}->setAttr(name=>"motherboard_state", value => "broken");
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
    # REmove motherboard from clusteR ?
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
    $args{motherboard}->setNodeState(state => "broken");
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
    $args{motherboard}->setNodeState(state => "out");

}

sub nodeIn{
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

sub testGoingInNodeBroken {
    #TODO Test how long node going in cluster
}
sub testGoingOutNodeBroken {
    #TODO Test how long node going out cluster
}

sub testStartingMotherboardBroken{
    #TODO Test how long motherboard starting
}

sub testStopingMotherboardBroken{
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
                          down      => \&incorrectMotherboard,
                          starting  => \&testStartingMotherboardBroken,
                          broken    => sub {},
                          stopping  => \&motherboardStopped},
                   1 => { broken    => \&motherboardRepaired,
                          up        => sub {},
                          down      => \&incorrectMotherboard,
                          starting  => \&motherboardStarted,
                          stopping  => \&testStopingMotherboardBroken});
   
   my $state = $args{motherboard}->getAttr(name=>"motherboard_state");
   my @tmp = split /:/, $state;
   $state = $tmp[0];
   print "UpdateMotherboardStatus state is $state for motherboard" . $args{motherboard}->getAttr(name=>"motherboard_mac_address") . "\n";
   my $method = $actions{$args{pingable}}->{$state} || \&incorrectStates;
    $method->(pingable=>$args{pingable},motherboard=>$args{motherboard});   
}

sub updateNodeStatus {
    my %args = @_;
    if ((!defined $args{services_available} or !exists $args{services_available})||
        (!defined $args{motherboard} or !exists $args{motherboard})){
            $errmsg = "StateManager::updateNodeStatus need a srv_available and motherboard named argument!";	
		    $log->error($errmsg);
		    throw Kanopya::Exception::Internal(error => $errmsg);
    }
    my %actions = (0 => { in        => \&nodeBroken,
                          goingin  => \&testGoingInNodeBroken,
                          broken    => sub {},
                          goingout  => \&nodeOut},
                   1 => { broken    => \&nodeRepaired,
                          in        => sub {},
                          goingin  => \&nodeIn,
                          goingout  => \&testGoingOutNodeBroken});
   my $node_state = $args{motherboard}->getNodeState();
   print "Node state is $node_state and service status is $args{services_available}\n";
   my $method = $actions{$args{services_available}}->{$node_state} || \&incorrectStates;
   $method->(services_available=>$args{services_available},motherboard=>$args{motherboard});
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
