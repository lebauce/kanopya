#    Copyright © 2011 Hedera Technology SAS
#
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

package EEntity::EOperation::EPostStartNode;
use base "EEntity::EOperation";

use strict;
use warnings;

use Kanopya::Exceptions;
use EEntity;
use Entity::ServiceProvider;
use Entity::ServiceProvider::Cluster;
use Entity::Host;

use Log::Log4perl "get_logger";
use Data::Dumper;
use String::Random;
use Date::Simple (':all');
use Template;

my $log = get_logger("");
my $errmsg;

sub check {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => $self->{context}, required => [ "cluster", "host" ]);
}

sub prerequisites {
    my $self  = shift;
    my %args  = @_;

    # Duration to wait before retrying prerequistes
    my $delay = 10;

    # Duration to wait for setting host broken
    my $broken_time = 240;

    my $host_id = $self->{context}->{host}->id;

    # Check how long the host is 'starting'
    my @state = $self->{context}->{host}->getState;
    my $starting_time = time() - $state[1];
    if($starting_time > $broken_time) {
        $self->{context}->{host}->timeOuted();
    }

    my $node_ip = $self->{context}->{host}->adminIp;
    if (not $node_ip) {
        throw Kanopya::Exception::Internal(error => "Host <$host_id> has no admin ip.");
    }
    
    if (! $self->{context}->{host}->checkUp()) {
        $log->debug("Host <$host_id> not yet reachable at <$node_ip>");
        return $delay;
    }

    # Check if all host components are up.
    if (not $self->{context}->{cluster}->checkComponents(host => $self->{context}->{host})) {
        return $delay;
    }

    # Node is up
    $self->{context}->{host}->setState(state => "up");
    $self->{context}->{host}->setNodeState(state => "in");

    $log->info("Host <$host_id> is 'up'");

    return 0;
}

sub execute {
    my ($self, %args) = @_;

    $self->SUPER::execute();

    $self->{context}->{cluster}->postStartNode(
        host      => $self->{context}->{host},
        erollback => $self->{erollback},
    );

    $self->{context}->{host}->postStart();

    # Update the user quota on ram and cpu
    $self->{context}->{cluster}->user->consumeQuota(
        resource => 'ram',
        amount   => $self->{context}->{host}->host_ram,
    );
    $self->{context}->{cluster}->user->consumeQuota(
        resource => 'cpu',
        amount   => $self->{context}->{host}->host_core,
    );
}

sub finish {
    my $self = shift;

    my @nodes = $self->{context}->{cluster}->getHosts();

    # Add another node if required
    if (scalar(@nodes) < $self->{context}->{cluster}->cluster_min_node) {
        # _entity is important here, cause we want to enqueue AddNode operation.
        $self->{context}->{cluster}->_entity->addNode();
    }
    else {
        my $nodes_states = 1;
        foreach my $node (@nodes) {
            my @node_state = $node->getNodeState();
            if ($node_state[0] ne "in"){
                $nodes_states = 0;
            }
        }
        if ($nodes_states) {
            $self->{context}->{cluster}->setState(state => "up");
        }
        else {
            # Another node that the current one is broken
        }
    }

    # /!\ WARNING: DO NOT DELETE $self->{context}->{host} ! needed in worflow addNode + VM migration

    delete $self->{context}->{cluster}; # Need to be deleted for Add hypervisor followed by add Vm
}

sub _cancel {
    my $self = shift;

    $log->info("Cancel post start node, we will try to remove node link for <" .
               $self->{context}->{host} . ">");

    eval {
        $self->{context}->{cluster}->unregisterNode(node => $self->{context}->{host}->node);
    };
    if ($@) {
        $log->debug($@);
    }

    if (! scalar(@{ $self->{context}->{cluster}->getHosts() })) {
        $self->{context}->{cluster}->setState(state => "down");
    }
}

1;
