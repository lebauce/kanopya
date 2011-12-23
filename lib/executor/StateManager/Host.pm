# StateManager::Host.pm - Object class of State Manager server

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

<StateManager::Host>  <StateManager::Host main class>

=head1 VERSION

This documentation refers to <StateManager::Host> version 1.0.0.

=head1 SYNOPSIS

use <Executor>;


=head1 DESCRIPTION

StateManager::Host is the main module to manage state

=head1 METHODS

=cut

package StateManager::Host;

use strict;
use warnings;

use Message;
use General;
use Kanopya::Exceptions;
use Operation;
use EFactory;

use Entity::Host;

use Log::Log4perl "get_logger";
our $VERSION = '1.00';

use Net::Ping;
use IO::Socket;

my $errmsg;
my $log = get_logger("statemanager");



################################### MOTHERBOARD STATES METHOD PART
sub hostBroken{
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['host']);
          
    $args{host}->setState('state' => "broken");
    
    logHostStateChange(
        level => 'warning',
        mac_address => $args{host}->getAttr(name=>"host_mac_address"),
        newstatus => 'broken' 
    );
}

sub hostRepaired{
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['host']);
    
    $args{host}->setState('state' => $args{host}->getPrevState());
    
    logHostStateChange(
        level => 'info',
        mac_address => $args{host}->getAttr(name=>"host_mac_address"),
        newstatus => 'up' 
    );
}

sub hostStopped{
    my %args = @_;
   
    General::checkParams(args => \%args, required => ['host']);
   
    $args{host}->setState('state' => "down");
    
    logHostStateChange(
        level => 'info',
        mac_address => $args{host}->getAttr(name=>"host_mac_address"),
        newstatus => 'down' 
    );
    
    my %params;
    $params{cluster_id} = $args{host}->getClusterId();
    $params{host_id} = $args{host}->getAttr(name=>"host_id");
    Operation->enqueue(priority => 200,
                   type     => 'PostStopNode',
                   params   => \%params);
}

sub hostStarted{
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['host']);
    
    $args{host}->setState('state' => "up");
    
    logHostStateChange(
        level => 'info',
        mac_address => $args{host}->getAttr(name=>"host_mac_address"),
        newstatus => 'up' 
    );

    
    my %params;
    $params{cluster_id} = $args{host}->getClusterId();
    $params{host_id} = $args{host}->getAttr(name=>"host_id");
    
    Operation->enqueue(priority => 200,
                   type     => 'PostStartNode',
                   params   => \%params);
}



############################# ERROR STATES VALUES

sub incorrectHost {
    my %args = @_;
    if ((!defined $args{host} or !exists $args{host})){
            $errmsg = "StateManager::incorrectHost need a host named argument!";    
            $log->error($errmsg);
            throw Kanopya::Exception::Internal(error => $errmsg);
        }
    my $error = "Wrong host <". $args{host}->getAttr(name=>'host_mac_address')."> must not be in cluster";
    throw Kanopya::Exception::Internal(error => $error);
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


sub testStartingHost{
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['pingable', 'host','begin_time']);
    my $diff_time = time() - $args{begin_time};
    #TODO get max boot time for the host from its model
    my $host_start_max_time = 240;
    if($diff_time>$host_start_max_time) {
        $args{host}->setState(state => 'broken');
    }
}


sub testStoppingHost{
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['pingable', 'host','begin_time']);
    my $diff_time = time() - $args{begin_time};
    #TODO get max boot time for the host from its model
    my $host_stop_max_time = 240;
    if($diff_time>$host_stop_max_time) {
        $args{host}->setState('state'=> 'broken');
    }
}
######################## UPDATE METHOD

sub updateHostStatus {
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['host']);

    my %actions = (0 => { up        => \&hostBroken,
                          starting  => \&testStartingHost,
                          broken    => sub {},
                          stopping  => \&hostStopped},
                   1 => { broken    => \&hostRepaired,
                          up        => sub {},
                          starting  => \&hostStarted,
                          stopping  => \&testStoppingHost});
   
   my $state = $args{host}->getAttr(name=>"host_state");
   my @tmp = split(/:/, $state);
   $state = $tmp[0];
   my $method = $actions{$args{pingable}}->{$state} || \&incorrectStates;
   $method->(pingable=>$args{pingable},host=>$args{host},begin_time => $tmp[1]);   
}


### log functions ###

sub logHostStateChange {
    my %args = @_;
    General::checkParams(args => \%args, required => ['mac_address', 'newstatus', 'level']);
    my $adm = Administrator->new();
    my $msg = "Host with mac address $args{mac_address} is now $args{newstatus}";
    Message->send(from => 'StateManager', level => $args{level}, content => $msg);
    $log->info($msg); 
}


1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
