# StateManager::Motherboard.pm - Object class of State Manager server

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

<StateManager::Motherboard>  <StateManager::Motherboard main class>

=head1 VERSION

This documentation refers to <StateManager::Motherboard> version 1.0.0.

=head1 SYNOPSIS

use <Executor>;


=head1 DESCRIPTION

StateManager::Motherboard is the main module to manage state

=head1 METHODS

=cut

package StateManager::Motherboard;

use strict;
use warnings;


use General;
use Kanopya::Exceptions;
use Operation;
use EFactory;

use Entity::Motherboard;

use Log::Log4perl "get_logger";
our $VERSION = '1.00';

use Net::Ping;
use IO::Socket;

my $errmsg;
my $log = get_logger("statemanager");



################################### MOTHERBOARD STATES METHOD PART
sub motherboardBroken{
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['motherboard']);
          
    $args{motherboard}->setAttr(name=>"motherboard_state", value => "broken:".time);
    $args{motherboard}->save();
    
    logMotherboardStateChange(
        level => 'warning',
        mac_address => $args{motherboard}->getAttr(name=>"motherboard_mac_address"),
        newstatus => 'broken' 
    );
}

sub motherboardRepaired{
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['motherboard']);
    
    $args{motherboard}->setAttr(name=>"motherboard_state", value => "up");
    $args{motherboard}->save();
    
    logMotherboardStateChange(
        level => 'info',
        mac_address => $args{motherboard}->getAttr(name=>"motherboard_mac_address"),
        newstatus => 'up' 
    );
}

sub motherboardStopped{
    my %args = @_;
   
    General::checkParams(args => \%args, required => ['motherboard']);
   
    $args{motherboard}->setAttr(name=>"motherboard_state", value => "down");
    $args{motherboard}->save();
    
    logMotherboardStateChange(
        level => 'info',
        mac_address => $args{motherboard}->getAttr(name=>"motherboard_mac_address"),
        newstatus => 'down' 
    );
    
    my %params;
    $params{cluster_id} = $args{motherboard}->getClusterId();
    $params{motherboard_id} = $args{motherboard}->getAttr(name=>"motherboard_id");
    Operation->enqueue(priority => 200,
                   type     => 'PostStopNode',
                   params   => \%params);
}

sub motherboardStarted{
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['motherboard']);
    
    $args{motherboard}->setAttr(name=>"motherboard_state", value => "up");
    $args{motherboard}->save();
    
    logMotherboardStateChange(
        level => 'info',
        mac_address => $args{motherboard}->getAttr(name=>"motherboard_mac_address"),
        newstatus => 'up' 
    );

    
    my %params;
    $params{cluster_id} = $args{motherboard}->getClusterId();
    $params{motherboard_id} = $args{motherboard}->getAttr(name=>"motherboard_id");
    
    Operation->enqueue(priority => 200,
                   type     => 'PostStartNode',
                   params   => \%params);
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


sub testStartingMotherboard{
    # Motherboard is Starting and is unpingable
    #TODO Test how long motherboard starting
}


sub testStoppingMotherboard{
    #If node is in
    # Foreach component TestReadytoBeRemoved
    #TODO Test how long motherboard stoping
}
######################## UPDATE METHOD

sub updateMotherboardStatus {
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['pingable', 'motherboard']);

    my %actions = (0 => { up        => \&motherboardBroken,
                          starting  => \&testStartingMotherboard,
                          broken    => sub {},
                          stopping  => \&motherboardStopped},
                   1 => { broken    => \&motherboardRepaired,
                          up        => sub {},
                          starting  => \&motherboardStarted,
                          stopping  => \&testStoppingMotherboard});
   
   my $state = $args{motherboard}->getAttr(name=>"motherboard_state");
   my @tmp = split(/:/, $state);
   $state = $tmp[0];
   my $method = $actions{$args{pingable}}->{$state} || \&incorrectStates;
   $method->(pingable=>$args{pingable},motherboard=>$args{motherboard},begin_time => $tmp[1]);   
}


### log functions ###

sub logMotherboardStateChange {
    my %args = @_;
    General::checkParams(args => \%args, required => ['mac_address', 'newstatus', 'level']);
    my $adm = Administrator->new();
    my $msg = "Motherboard with mac address $args{mac_address} is now $args{newstatus}";
    $adm->addMessage(from => 'StateManager', level => $args{level}, content => $msg);
    $log->info($msg); 
}


1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
