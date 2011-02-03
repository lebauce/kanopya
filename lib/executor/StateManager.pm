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

sub checkMotherboardUp {
    my $host_ip = $motherboards->{$mb}->getAttr( name => 'motherboard_internal_ip' );
				my $p = Net::Ping->new();
				my $pingable = $p->ping($host_ip);
				$p->close();
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
		        updateMotherboardStatus(pingable => $pingable, motherboard=>$motherboards->{$mb});
		        updateNodeStatus(motherboard=>$motherboards->{$mb}, cluster=>$cluster);
   	        }
   	    }
   		sleep 10;
   	}
   	my $motherboards = Entity::Motherboard->getMotherboards(hash => {-or => [motherboard_state => {'like','starting%'},
   	                                                                                       {'like','stoping%'}]});
   	my @moth_index = keys %$motherboards;
   	foreach my $mb (@moth_index) {
		my $pingable = checkMotherboardUp(ip => $motherboards->{$mb}->getAttr( name => 'motherboard_internal_ip' ));
		updateMotherboardStatus(pingable => $pingable, motherboard=>$motherboards->{$mb});
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
    #Update cluster ?
}

################################### NODE STATES METHOD PART

sub nodeBroken{
    my %args = @_;
    if ((!defined $args{motherboard} or !exists $args{motherboard})){
            $errmsg = "StateManager::motherboardBroken need a motherboard named argument!";	
		    $log->error($errmsg);
		    throw Kanopya::Exception::Internal(error => $errmsg);
        }
        print "motherboard". $args{motherboard}->getAttr(name=>"motherboard_mac_address")." broken\n";
    $args{motherboard}->setAttr(name=>"node_state", value => "broken");
    $args{motherboard}->save();
}

sub nodeRepaired{
    my %args = @_;
    if ((!defined $args{motherboard} or !exists $args{motherboard})){
            $errmsg = "StateManager::motherboardBroken need a motherboard named argument!";	
		    $log->error($errmsg);
		    throw Kanopya::Exception::Internal(error => $errmsg);
        }
    $args{motherboard}->setAttr(name=>"motherboard_state", value => "up");
    $args{motherboard}->save();
}

sub nodeStopped{
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

sub nodeStarted{
    my %args = @_;
    if ((!defined $args{motherboard} or !exists $args{motherboard})){
            $errmsg = "StateManager::motherboardStarted need a motherboard named argument!";	
		    $log->error($errmsg);
		    throw Kanopya::Exception::Internal(error => $errmsg);
        }
    $args{motherboard}->setAttr(name=>"motherboard_state", value => "up");
    $args{motherboard}->save();
    #Update cluster ?
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
        (!defined $args{pingable} or !exists $args{pingable})){
            $errmsg = "StateManager::incorrectStates need a motherboard and pingable named argument!";	
		    $log->error($errmsg);
		    throw Kanopya::Exception::Internal(error => $errmsg);
        }
    my $error = "Wrong motherboard <". $args{motherboard}->getAttr(name=>'motherboard_mac_address')."> state <". $args{motherboard}->getAttr(name=>'motherboard_state') ."> or pingable value <$args{pingable}>";
    throw Kanopya::Exception::Internal(error => $error);
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
                          starting  => sub {},
                          broken    => sub {},
                          stopping  => \&motherboardStopped},
                   1 => { broken    => \&motherboardRepaired,
                          up        => sub {},
                          down      => \&incorrectMotherboard,
                          starting  => \&motherboardStarted,
                          stopping  => sub {}});
   print "Pingable : $args{pingable} for motherboard state " . $args{motherboard}->getAttr(name=>"motherboard_state")."\n";
   my $tmp = $args{motherboard}->getAttr(name=>"motherboard_state");
   my $method = $actions{$args{pingable}}->{$tmp} || \&incorrectStates;
    $method->(pingable=>$args{pingable},motherboard=>$args{motherboard});   
}

sub updateNodeStatus {
    my %args = @_;
    if ((!defined $args{cluster} or !exists $args{cluster})||
        (!defined $args{motherboard} or !exists $args{motherboard})){
            $errmsg = "StateManager::updateNodeStatus need a cluster and motherboard named argument!";	
		    $log->error($errmsg);
		    throw Kanopya::Exception::Internal(error => $errmsg);
    }
    my %actions = (0 => { in        => \&nodeBroken,
                          goingin  => sub {},
                          broken    => sub {},
                          goingout  => \&nodeStopped},
                   1 => { broken    => \&nodeRepaired,
                          in        => sub {},
                          goingin  => \&nodeStarted,
                          goingout  => sub {}});
$hostName = notesserver;
my $host = shift || $hostName;
my $port = shift || 25;
my $sock = new
IO::Socket::INET(PeerAddr=>$host,PeerPort=>$port,P roto=>'tcp');
if($sock)
{
print "<script>
alert(\"Server notesserver is running...\");
history.back();
</script>";
exit;
}
else
{
print "<script>
alert(\"Server notesserver appears to be down...\");
history.back();
</script>";
exit;
}
close $sock or die "close: $!";
    
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
