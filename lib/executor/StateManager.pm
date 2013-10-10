# Copyright 2011-2013 Hedera Technology SAS
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
use base Daemon;

use strict;
use warnings;

use Kanopya::Config;
use Kanopya::Exceptions;
use Entity::ServiceProvider::Cluster;

use BaseDB;
use Message;
use Alert;
use EEntity;

use Log::Log4perl "get_logger";
use Data::Dumper;

use XML::Simple;
use Net::Ping;
use IO::Socket;

my $errmsg;
my $log = get_logger("");

sub new {
    my ($class) = @_;

    return $class->SUPER::new(confkey => 'executor', name => 'Executor');
}

sub oneRun {
    my ($self) = @_;

    # Check all nodes services availability
    my @clusters = Entity::ServiceProvider::Cluster->search(hash => {}, prefetch => [ 'nodes.host' ]);

    $log->info('---------------------------------------------');
    $log->info('***** Check ' . scalar (@clusters) . ' services availability *****');

    CLUSTER:
    foreach my $cluster (@clusters) {
        my @nodes = $cluster->getHosts();

        my $services_available = 1;
        if (! scalar(@nodes)) {
            # we deactive all alerts for this cluster
            my @alerts = Alert->search(hash => { alert_active => 1, entity_id => $cluster->id });
            for my $alert(@alerts) {
                $alert->mark_resolved;
            }
            next CLUSTER;
        }

        $log->info('---------------------------------------------');
        $log->info('***** Check ['.$cluster->cluster_name.'] service availability on ' . scalar(@nodes) . ' nodes *****');
        foreach my $node (@nodes) {
            my $ehost = EEntity->new(data => $node);

            $cluster->beginTransaction;

            # Firstly try to ping the node
            my $pingable;
            my $hostname = $ehost->node->node_hostname;
            my $hostmsg  = "Host $hostname not reachable";

            eval {
               $pingable = $ehost->checkUp();
            };

            my ($hoststate, $hosttimestamp) = $ehost->getState;

            $log->debug("Host pingable status <$pingable>, state <$hoststate>");

            if ((! $pingable) and $hoststate eq 'up') {
                my $msg = "Node " . $node->node->node_hostname . " unreachable in cluster :" . $cluster->cluster_name;
                $log->warn($msg);
                Message->send(from => 'StateManager', level => 'info', content => $msg);

                # create an alert if not already created
                Alert->throw(entity_id      => $cluster->id,
                             alert_message  => $hostmsg,
                             trigger_entity => $node);

                # Set the host and node states to broken
                $ehost->setState(state => 'broken');
                $ehost->setNodeState(state => 'broken');
                $cluster->setState(state => 'warning');

                $cluster->commitTransaction;
                next;
            }
            elsif ($pingable and $hoststate eq 'broken') {
                # Host has been repaired
                my ($prevstate, $prevtimestamp) = $ehost->getPrevState;
                $log->debug("Set host state to $prevstate");
                $ehost->setState(state => $prevstate);

                # disable the alert if it exists
                Alert->resolve(entity_id      => $cluster->id,
                               alert_message  => $hostmsg,
                               trigger_entity => $node);
            }

            # Then check the node component availability
            my $node_available = 1;
            my @components = $cluster->getComponents(category => "all");
            foreach my $component (@components) {
                my $ecomponent = EEntity->new(data => $component);
                my $component_name = $component->component_type->component_name;

                $log->debug("Check component availability : " . $component_name);

                my $compmsg = "Component $component_name unreachable on Host $hostname";

                if (! $ecomponent->isUp(host => $ehost, cluster => $cluster)) {
                    my $msg = $component_name .
                              " not available on node (" . $node->node->node_hostname .
                              ") in cluster (" . $cluster->cluster_name . ")";

                    Alert->throw(entity_id      => $cluster->id,
                                 alert_message  => $compmsg,
                                 trigger_entity => $node);

                    $log->warn($msg);

                    $node_available = 0;
                    $services_available = 0;
                    last;

                }
                else {
                    # disable the alert if it exists
                    Alert->resolve(entity_id      => $cluster->id,
                                   alert_message  => $compmsg,
                                   trigger_entity => $node);
                }
            }
            my ($nodestate, $nodetimestamp) = $ehost->getNodeState;
            if (! $node_available and $nodestate eq 'in') {
                # Set the node state to broken
                $ehost->setNodeState(state => 'broken');
                $cluster->setState(state => 'warning');
                $cluster->commitTransaction;
                next;
            }
            elsif ($node_available and $nodestate eq 'broken') {
                # Set the node is repaired
                $ehost->setNodeState(state => 'in');
            }

            $cluster->commitTransaction;
        }

        $cluster->beginTransaction;

        my ($clusterstate, $clustertimestamp) = $cluster->getState;
        if ($services_available and $clusterstate eq 'warning') {
            # Set the cluster as repaired
            $cluster->setState(state => 'up');
        }

        $cluster->commitTransaction;
    }
    sleep 20;
}

1;
