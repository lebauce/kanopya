# EPostStartNode.pm - Operation class implementing Cluster creation operation

#    Copyright © 2011 Hedera Technology SAS
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

EEntity::Operation::EAddHost - Operation class implementing Host creation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement Host creation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EPostStartNode;
use base "EOperation";

use strict;
use warnings;

use Kanopya::Exceptions;
use EFactory;
use Entity::ServiceProvider;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Host;

use Log::Log4perl "get_logger";
use Data::Dumper;
use String::Random;
use Date::Simple (':all');
use Template;

my $log = get_logger("executor");
my $errmsg;

sub check {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => $self->{context}, required => [ "cluster", "host" ]);
}

=head2 prepare

=cut

sub prerequisites {
    my $self  = shift;
    my %args  = @_;

    # Duration to wait before retrying prerequistes
    my $delay = 10;

    # Duration to wait for setting host broken
    my $broken_time = 240;

    my $cluster_id = $self->{context}->{cluster}->getAttr(name => 'entity_id');
    my $host_id    = $self->{context}->{host}->getAttr(name => 'entity_id');

    # Check how long the host is 'starting'
    my @state = $self->{context}->{host}->getState;
    my $starting_time = time() - $state[1];

    if($starting_time > $broken_time) {
        $self->{context}->{host}->setState(state => 'broken');
    }

    my $node_ip = $self->{context}->{host}->getAdminIp;
    if (not $node_ip) {
        throw Kanopya::Exception::Internal(error => "Host <$host_id> has no admin ip.");
    }

    # Instanciate an econtext to try initiating an ssh connexion.
    eval {
        $self->{context}->{host}->getEContext;
    };
    if ($@) {
        $log->debug("Could not connect to host <$host_id> from cluster <$cluster_id> with ip <$node_ip>.");
        return $delay;
    }

    # Check if all host components are up.
    my $components = $self->{context}->{cluster}->getComponents(category => "all");
    foreach my $key (keys %$components) {
        my $component_name = $components->{$key}->getComponentAttr()->{component_name};
        $log->debug("Browse component: " . $component_name);

        my $ecomponent = EFactory::newEEntity(data => $components->{$key});

        if (not $ecomponent->isUp(host => $self->{context}->{host}, cluster => $self->{context}->{cluster})) {
            $log->debug("Component <$component_name> on host <$host_id> from cluster <$cluster_id> not up.");
            return $delay;
        }
    }

    # Node is up
    $self->{context}->{host}->setState(state => "up");
    $self->{context}->{host}->setNodeState(state => "in");

    $log->debug("Host <$host_id> in cluster <$cluster_id> is 'up', preparing PostStartNode.");
    return 0;
}

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    my $exec_cluster = Entity::ServiceProvider->get(id => $self->{config}->{cluster}->{executor});
    $self->{params}->{kanopya_domainname} = $exec_cluster->getAttr(name => 'cluster_domainname');
}

sub execute {
    my $self = shift;
    $self->SUPER::execute();
    
    if (not $self->{context}->{cluster}->getMasterNodeId()) {
        $self->{context}->{host}->becomeMasterNode();
    }

    my $components = $self->{context}->{cluster}->getComponents(category => "all");
    $log->info('Processing cluster components configuration for this node');
    foreach my $i (keys %$components) {
        my $comp = EFactory::newEEntity(data => $components->{$i});
        $log->debug("component is ".ref($comp));
        $comp->postStartNode(host    => $self->{context}->{host},
                             cluster => $self->{context}->{cluster});
    }

    $self->{context}->{cluster}->updateHostsFile(
        kanopya_domainname => $self->{params}->{kanopya_domainname},
        host               => $self->{context}->{host}
    );

    $self->{context}->{host}->postStart();
}

sub finish {
    my $self = shift;

    my $cluster_nodes = $self->{context}->{cluster}->getHosts();

    # Add another node if required
    if ((scalar keys %$cluster_nodes) < $self->{context}->{cluster}->getAttr(name => "cluster_min_node")) {
        # _getEntity is important here, cause we want to enqueue AddNode operation.
        $self->{context}->{cluster}->_getEntity->addNode();
    }
    else {
        my $nodes_states = 1;
        foreach my $node (keys %$cluster_nodes) {
            my @node_state = $cluster_nodes->{$node}->getNodeState();
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
}

sub _cancel {
    my $self = shift;

    $log->info("Cancel post start node, we will try to remove node link for <" .
               $self->{context}->{host}->getAttr(name => "entity_id") . ">");

    eval {
        $self->{context}->{host}->stopToBeNode();
    };
    if ($@) {
        $log->debug($@);
    }

    my $hosts = $self->{context}->{cluster}->getHosts();
    if (! scalar keys %$hosts) {
        $self->{context}->{cluster}->setState(state => "down");
    }
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
