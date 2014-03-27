#    Copyright © 2011-2013 Hedera Technology SAS
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


sub check {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => $self->{context}, required => [ "cluster" ]);
}


sub execute {
    my $self = shift;

    # Instanciate bootserver Cluster
    my $bootserver = Entity::ServiceProvider::Cluster->getKanopyaCluster;

    # Instanciate dhcpd component.
    $self->{context}->{component_dhcpd}
        = EEntity->new(data => $bootserver->getComponent(name => "Dhcpd", version => "3"));
 
    foreach my $node (reverse $self->{context}->{cluster}->nodesByWeight()) {
        my $ehost = EEntity->new(data => $node->host);
        eval {
            # Halt Node
            $ehost->halt();
        };
        if ($@) {
            my $error = $@;
            $errmsg = "Problem with node <" . $node->host->host_id . "> during force stop cluster : $error";
            $log->warn($errmsg);
        }

        eval {
            # Update Dhcp component conf
            $self->{context}->{component_dhcpd}->removeHost(
                host => $node->host
            );
        };
        if ($@) {
            my $error = $@;
            $errmsg = "Problem with node <" . $node->host->id .
                      "> during dhcp configuration update : $error";
            $log->warn($errmsg);
        }

        # component migration
        $log->info('Processing cluster components quick remove for node <' . $node->host->id . '>');

        my @components = $self->{context}->{cluster}->getComponents(category => "all");
        foreach my $component (@components) {
            EEntity->new(data => $component)->cleanNode(
                host        => $ehost,
                mount_point => '',
                cluster     => $self->{context}->{cluster}
            );
        }

        $node->node_hostname(undef);
        $node->host->host_initiatorname(undef);

        $self->{context}->{cluster}->unregisterNode(node => $node);
    }

    # Generate and reload Dhcp conf
    $self->{context}->{component_dhcpd}->applyConfiguration();

    $self->{context}->{cluster}->setState(state => "down");
}

1;
