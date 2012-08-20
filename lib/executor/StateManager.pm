# Copyright 2011 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package StateManager;

use strict;
use warnings;

use Kanopya::Config;
use Kanopya::Exceptions;
use Entity::ServiceProvider::Inside::Cluster;

use Message;
use EFactory;

use Log::Log4perl "get_logger";
use Data::Dumper;

use XML::Simple;
use Net::Ping;
use IO::Socket;

my $errmsg;
my $log = get_logger("");

sub new {
    my ($class) = @_;
    my $self = {};

    bless $self, $class;

    $self->{config} = Kanopya::Config::get('executor');

    if ((! exists $self->{config}->{user}->{name}     || ! defined exists $self->{config}->{user}->{name}) &&
        (! exists $self->{config}->{user}->{password} || ! defined exists $self->{config}->{user}->{password})) {
        throw Kanopya::Exception::Internal::IncorrectParam(error => "StateManager->new need user definition in config file!");
    }

    my $adm = Administrator::authenticate(login => $self->{config}->{user}->{name}, password => $self->{config}->{user}->{password});

    return $self;
}

=head2 run

StateManager->run() run the state manager server.

=cut

sub run {
    my ($self, $running) = @_;

    my $adm = Administrator->new();

    Message->send(from => 'StateManager', level => 'info', content => "Kanopya State Manager started.");

    # Main loop
    while ($$running) {
        # Check all nodes services availability
        my @clusters = Entity::ServiceProvider::Inside::Cluster->search(hash => {});
        CLUSTER:
        foreach my $cluster (@clusters) {

            my $nodes = $cluster->getHosts();
            my $services_available = 1;
            if(!scalar(values %$nodes)) {
                next CLUSTER;
            }
            $log->info('---------------------------------------------');
            $log->info('***** Check ['.$cluster->cluster_name.'] service availability on '.scalar(values %$nodes).' nodes *****');
            foreach my $node (values %$nodes) {
                my $ehost = EFactory::newEEntity(data => $node);

                $adm->{db}->txn_begin;

                # Firstly try to ping the node
                my $pingable;
                eval {
                   $pingable = $ehost->checkUp();
                };

                my ($hoststate, $hosttimestamp) = $ehost->getState;

                if (! $pingable and $hoststate eq 'up') {
                    my $msg = "Node " . $node->host_hostname . " unreachable in cluster :" . $cluster->cluster_name;
                    $log->warn($msg);

                    Message->send(from => 'StateManager', level => 'info', content => $msg);

                    # Set the host and node states to broken
                    $ehost->setState(state => 'broken');
                    $ehost->setNodeState(state => 'broken');
                    $cluster->setState(state => 'warning');

                    $adm->{db}->txn_commit;
                    next;
                }
                elsif ($pingable and $hoststate eq 'broken') {
                    # Host has been repaired
                    my ($prevstate, $prevtimestamp) = $ehost->getPrevState;

                    $ehost->setState(state => $prevstate);
                }

                # Then check the node component availability
                my $node_available = 1;
                my $components = $cluster->getComponents(category => "all");
                foreach my $component (values %$components) {
                    my $ecomponent = EFactory::newEEntity(data => $component);
                    my $component_name = $component->getComponentAttr->{component_name};

                    $log->debug("Check component availability : " . $component_name);

                    if (! $ecomponent->isUp(host => $ehost, cluster => $cluster)) {
                        my $msg = $component_name .
                                  " not available on node (" . $node->host_hostname .
                                  ") in cluster (" . $cluster->cluster_name . ")";
                        $log->warn($msg);

                        Message->send(from => 'StateManager', level => 'info', content => $msg);

                        $node_available = 0;
                        $services_available = 0;
                        last;
                    }
                }
                my ($nodestate, $nodetimestamp) = $ehost->getNodeState;
                if (! $node_available and $nodestate eq 'in') {
                    # Set the node state to broken
                    $ehost->setNodeState(state => 'broken');
                    $cluster->setState(state => 'warning');
                    $adm->{db}->txn_commit;
                    next;
                }
                elsif ($node_available and $nodestate eq 'broken') {
                    # Set the node is repaired
                    $ehost->setNodeState(state => 'in');
                }

                $adm->{db}->txn_commit;
            }

            $adm->{db}->txn_begin;

            my ($clusterstate, $clustertimestamp) = $cluster->getState;
            if ($services_available and $clusterstate eq 'warning') {
                # Set the cluster as repaired
                $cluster->setState(state => 'up');
            }

            $adm->{db}->txn_commit;
       }
       sleep 20;
   }

   Message->send(from => 'StateManager', level => 'warning', content => "Kanopya State Manager stopped");
}


1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
