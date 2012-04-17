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

<StateManager>  <StateManager main class>

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
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Host;
use Message;

use StateManager::Host;
use StateManager::Cluster;
use StateManager::Node;

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


=head2 run

Executor->run() run the executor server.

=cut

sub run {
    my $self = shift;
    my $running = shift;
    
    my $adm = Administrator->new();
    Message->send(from => 'StateManager', level => 'info', content => "Kanopya State Manager started.");
    
    # main loop
    while ($$running) {
        # First Check Host status
        
        $log->debug("<<< Hosts status changes >>>");
        my @hosts = Entity::Host->getHosts(hash => {-not => {host_state => {'like','down%'}}});
        @hosts = grep {$_->getState() !~ /^locked:/} @hosts;
        foreach my $mb (@hosts) {
            $adm->{db}->txn_begin;
            eval {
                print "loop on not down host <" . $mb->getAttr(name => "entity_id") . ">\n";
                my $ehost = EFactory::newEEntity(data => $mb);
                my $is_up = $ehost->checkUp();
                StateManager::Host::updateHostStatus(pingable => $is_up, host => $mb);
            };
            if($@) {
                my $exception = $@;
                $adm->{db}->txn_rollback;
                Message->send(from => 'StateManager', level => 'error', content => $exception);
                $log->error($exception);
            } else {
                $adm->{db}->txn_commit; 
            }
        }

        # Second Check clusters's nodes status
        $log->debug("<<< Clusters'nodes status changes >>>");
        my @clusters = Entity::ServiceProvider::Inside::Cluster->getClusters(hash=>{-not => {cluster_state => {'like','down%'}}});
        foreach my $cluster (@clusters) {
                        
            $log->debug("On cluster " . $cluster->getAttr(name=>'cluster_name')." ...");
            my $hosts = $cluster->getHosts();
            my @moth_index = keys %$hosts;
            foreach my $mb (@moth_index) {
                $adm->{db}->txn_begin;
                eval {
                    my $executor = Entity::ServiceProvider::Inside::Cluster->get(id => $self->{config}->{cluster}->{executor});
                    my $srv_available = StateManager::Node::checkNodeUp(host        => $hosts->{$mb}, 
                                                                        cluster     => $cluster,
                                                                        executor_ip => $executor->getMasterNodeIp());

                    StateManager::Node::updateNodeStatus(host => $hosts->{$mb}, services_available => $srv_available, cluster => $cluster);
                };
                if($@) {
                    my $exception = $@;
                    $adm->{db}->txn_rollback;
                    Message->send(from => 'StateManager', level => 'error', content => $exception);
                    $log->error($exception);
                } else {
                 $adm->{db}->txn_commit; 
                }
            }
            
            $adm->{db}->txn_begin;
            eval {
                StateManager::Cluster::updateClusterStatus(hosts=>$hosts,cluster=>$cluster);
            };
            if($@) {
                my $exception = $@;
                $adm->{db}->txn_rollback;
                Message->send(from => 'StateManager', level => 'error', content => $exception);
                $log->error($exception);
            } else {
              $adm->{db}->txn_commit; 
            }
       }
           
       sleep 10;
   }

   Message->send(from => 'StateManager', level => 'warning', content => "Kanopya State Manager stopped");
}


1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
