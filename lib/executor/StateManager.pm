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

use strict;
use warnings;

use Kanopya::Config;
use Kanopya::Exceptions;
use Entity::ServiceProvider::Cluster;

use BaseDB;
use Message;
use Alert;
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

    BaseDB->authenticate(login => $self->{config}->{user}->{name},
                         password => $self->{config}->{user}->{password});

    return $self;
}

=head2 run

StateManager->run() run the state manager server.

=cut

sub run {
    my ($self, $running) = @_;

    Message->send(from => 'StateManager', level => 'info', content => "Kanopya State Manager started.");

    # Main loop
    while ($$running) {
        # Excecute one loop
       $self->oneRun();

       sleep 20;
    }

    Message->send(from => 'StateManager', level => 'warning', content => "Kanopya State Manager stopped");
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
            my $ehost = EFactory::newEEntity(data => $node);

            $cluster->beginTransaction;

            # Firstly try to ping the node
            my $pingable;
            my $hostalert;
            my $hostname = $ehost->node->node_hostname;
            my $hostmsg  = "Host $hostname not reachable";
            # search if an alert exists
            eval {
                $hostalert = Alert->find(hash => {
                                 alert_active  => 1,
                                 alert_message => $hostmsg,
                                 entity_id     => $cluster->id
                             });
            };

            eval {
               $pingable = $ehost->checkUp();
            };

            my ($hoststate, $hosttimestamp) = $ehost->getState;

            if (! $pingable and $hoststate eq 'up') {
                my $msg = "Node " . $node->node->node_hostname . " unreachable in cluster :" . $cluster->cluster_name;
                $log->warn($msg);
                Message->send(from => 'StateManager', level => 'info', content => $msg);

                # create an alert if not already created
                if(not $hostalert) {
                    Alert->new(entity_id => $cluster->id, alert_message => $hostmsg, alert_signature => $hostmsg.' '.time());
                    $log->warn($msg);
                }

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
                $ehost->setState(state => $prevstate);

                # disable the alert if it exists
                if ($hostalert) {
                    $hostalert->mark_resolved;
                }
            }

            # Then check the node component availability
            my $node_available = 1;
            my @components = $cluster->getComponents(category => "all");
            foreach my $component (@components) {
                my $ecomponent = EFactory::newEEntity(data => $component);
                my $component_name = $component->component_type->component_name;

                $log->debug("Check component availability : " . $component_name);

                # search if an alert exists
                my $compmsg = "Component $component_name unreachable on Host $hostname";
                my $compalert;
                eval {
                    $compalert = Alert->find(hash => {
                                     alert_active  => 1,
                                     alert_message => $compmsg,
                                     entity_id     => $cluster->id
                                 });
                };

                if (! $ecomponent->isUp(host => $ehost, cluster => $cluster)) {
                    my $msg = $component_name .
                              " not available on node (" . $node->node->node_hostname .
                              ") in cluster (" . $cluster->cluster_name . ")";
                    #$log->warn($msg);

                    #Message->send(from => 'StateManager', level => 'info', content => $msg);

                    # create an alert if not already created
                    if(not $compalert) {
                        Alert->new(entity_id => $cluster->id, alert_message => $compmsg, alert_signature => $compmsg.' '.time());
                        $log->warn($msg);
                    }

                    $node_available = 0;
                    $services_available = 0;
                    last;

                } else {
                    # disable the alert if it exists
                    if ($compalert) {
                        $compalert->mark_resolved;
                    }
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
}

1;
