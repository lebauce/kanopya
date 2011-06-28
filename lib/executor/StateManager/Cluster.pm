# StateManager::Cluster.pm - Object class of State Manager server

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

<StateManager::Cluster>  <StateManager::Cluster main class>

=head1 VERSION

This documentation refers to <StateManager::Cluster> version 1.0.0.

=head1 SYNOPSIS

use <Executor>;


=head1 DESCRIPTION

StateManager::Cluster is the main module to manage state

=head1 METHODS

=cut

package StateManager::Cluster;

use strict;
use warnings;


use General;
use Kanopya::Exceptions;
use Operation;
use EFactory;

use Entity::Cluster;


use XML::Simple;
use Data::Dumper;
use Log::Log4perl "get_logger";
our $VERSION = '1.00';

use Net::Ping;
use IO::Socket;

my $errmsg;
my $log = get_logger("statemanager");


sub updateClusterStatus {
    my %args = @_;
    General::checkParams(\%args, ['cluster','motherboards']);
   
    my $motherboards = $args{motherboards};
    # third Check Cluster Status
    my @cluster_state = split(/:/, $args{cluster}->getAttr(name=>"cluster_state"));
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
                logClusterStateChange(
                    cluster_name => $args{cluster}->getAttr(name=>"cluster_name"),
                    level => 'info',
                    newstatus => 'up',    
                );
                            
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
            logClusterStateChange(
                    cluster_name => $args{cluster}->getAttr(name=>"cluster_name"),
                    level => 'info',
                    newstatus => 'down',    
            );
            
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
            if ($motherboards->{$master_id}->getNodeState() eq "in"){
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

sub logClusterStateChange {
    my %args = @_;
    General::checkParams(args => \%args, required => ['cluster_name', 'newstatus', 'level']);
    my $adm = Administrator->new();
    my $msg = "Cluster $args{cluster_name} is now $args{newstatus}";
    $adm->addMessage(from => 'StateManager', level => $args{level}, content => $msg);
    $log->info($msg); 
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
