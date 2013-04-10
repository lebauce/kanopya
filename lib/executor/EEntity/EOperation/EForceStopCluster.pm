# EForceStopCluster.pm - Operation class node removing from cluster operation

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

package EEntity::EOperation::EForceStopCluster;
use base "EEntity::EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;

use Kanopya::Exceptions;
use Entity;

use EEntity;

my $log = get_logger("");
my $errmsg;


sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    General::checkParams(args => $self->{context}, required => [ "cluster" ]);

    # Instanciate bootserver Cluster
    my $bootserver = Entity::ServiceProvider::Cluster->getKanopyaCluster;

    # Instanciate dhcpd component.
    $self->{context}->{component_dhcpd}
        = EEntity->new(data => $bootserver->getComponent(name => "Dhcpd", version => "3"));
}

sub execute {
    my $self = shift;
    $self->SUPER::execute();

    my $subnet = $self->{context}->{component_dhcpd}->getInternalSubNetId();

    foreach my $node (reverse $self->{context}->{cluster}->nodesByWeight()) {
        eval {
            # Halt Node
            my $ehost = EEntity->new(data => $node);
            $ehost->halt();
        };
        if ($@) {
            my $error = $@;
            $errmsg = "Problem with node <" . $node->host_id . "> during force stop cluster : $error";
            $log->warn($errmsg);
        }

        eval {
            # Update Dhcp component conf
            my $host_mac = $node->getPXEIface->iface_mac_addr;
            if ($host_mac) {
	            my $hostid = $self->{context}->{component_dhcpd}->getHostId(
	                             dhcpd3_subnet_id         => $subnet,
	                             dhcpd3_hosts_mac_address => $host_mac
	                         );

	            $self->{context}->{component_dhcpd}->removeHost(dhcpd3_subnet_id => $subnet,
	                                                            dhcpd3_hosts_id  => $hostid);
            }
        };
        if ($@) {
            my $error = $@;
            $errmsg = "Problem with node <" . $node->getAttr(name=>"host_id").
                      "> during dhcp configuration update : $error";
            $log->warn($errmsg);
        }

        # component migration
        $log->info('Processing cluster components quick remove for node <' . $node->host->id . '>');

        my @components = $self->{context}->{cluster}->getComponents(category => "all");
        foreach my $component (@components) {
            EEntity->new(data => $component)->cleanNode(
                host => $node, mount_point => '', cluster => $self->{context}->{cluster}
            );
        }

        $node->node->setAttr(name => "node_hostname", value => undef, save => 1);
        $node->setAttr(name => "host_initiatorname", value => undef, save => 1);

        $self->{context}->{cluster}->unregisterNode(node => $node);
    }

    # Generate and reload Dhcp conf
    $self->{context}->{component_dhcpd}->generate();
    $self->{context}->{component_dhcpd}->reload();

    $self->{context}->{cluster}->setState(state => "down");
}

1;
