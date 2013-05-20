# HostSelector.pm - Select better fit host according to context, constraints and choice policy

#    Copyright © 2011-2012 Hedera Technology SAS
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

=pod

=begin classdoc

Select better fit host according to context, constraints and choice policy

=end classdoc

=cut

package DecisionMaker::HostSelector;

use strict;
use warnings;

use JSON;
use Cwd;

use General;
use Entity;
use Entity::Host;
use Kanopya::Exceptions;

use Data::Dumper;
use Log::Log4perl "get_logger";

my $log = get_logger("");

use constant {
    JAR_DIR  => "/tools/deployment_solver/",
    JAR_NAME => "deployment_solver.jar",
};

=pod

=begin classdoc

Select and return the more suitable host according to constraints

All constraints args are optional, not defined means no constraint for this arg
Final constraints are intersection of input constraints and cluster components contraints.

@optional core min number of desired core
@optional ram  min amount of desired ram  # TODO manage unit (M,G,..)
@optional interfaces Interfaces of the 

@return Entity::Host

=end classdoc

=cut

sub getHost {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "cluster" ]);

    my $cluster      = $args{cluster};
    my $host_params  = $cluster->getManagerParameters(manager_type => "HostManager");

    my $host_manager = $cluster->getManager(manager_type => "HostManager");
    my @free_hosts   = $host_manager->getFreeHosts();

    # Generate Json objects for the external module (infrastructure and constraints)

    # INFRASTRUCTURE
    my @json_infrastructure;
    for my $host (@free_hosts) {

        # Construct json ifaces (bonds number + netIPs)
        my @json_ifaces;
        for my $iface (@{ $host->getIfaces() }) {
            my @netconfs = $iface->netconfs;
            my @networks;
            for my $netconf (@netconfs) {
                @networks = (@networks, map { $_->network->id } $netconf->poolips);
            }
            my $json_iface = {
                bondsNumber => scalar(@{ $iface->slaves }) + 1,
                netIPs    => \@networks,
            };
            push @json_ifaces, $json_iface;
        }
        # Construct the current host
        my $current = {
            cpu     => {
                nbCores => $host->host_core,
            },
            ram     => {
                qty     => $host->host_ram/1024/1024,
            },
            network => {
                ifaces  => \@json_ifaces,
            },
        };
        push @json_infrastructure, $current;
    }

    # CLUSTER CONSTRAINTS

    # Construct json interfaces (bonds number + netIPs)
    my @json_interfaces;
    for my $interface ($cluster->interfaces) {
        my @netconfs = $interface->netconfs;
        my @networks;
        for my $netconf (@netconfs) {
            @networks = (@networks, map { $_->network->id } $netconf->poolips);
        }
        my $json_interface = {
            bondsNumberMin => $interface->bonds_number + 1,
            netIPsMin    => \@networks,
        };
        push @json_interfaces, $json_interface;
    }

    # Construct the constraint json object
    my $json_constraints = {
        cpu     => {
            nbCoresMin => $host_params->{core},
        },
        ram     => {
            qtyMin     => $host_params->{ram}/1024/1024,
        },
        network => {
            interfaces => \@json_interfaces,
        },
    };

    # Get current working directory
    my $dir             = getcwd();
    my $infra_dir       = $dir . "/hosts.json";
    my $constraints_dir = $dir . "/constraints.json";
    my $result_dir      = $dir . "/result.json";

    my $hosts_json = JSON->new->utf8->encode(\@json_infrastructure);

    open (my $FILE1, '>', $infra_dir) or die "could not $infra_dir : $!\n";
    print $FILE1 $hosts_json;
    close($FILE1);

    my $constraints_json = JSON->new->utf8->encode($json_constraints);
    open (my $FILE2, '>', $constraints_dir) or die "could not create $constraints_dir : $!\n";
    print $FILE2 $constraints_json;
    close($FILE2);

    my $jar = Kanopya::Config->getKanopyaDir() . JAR_DIR . JAR_NAME;

    system "java -jar $jar $infra_dir $constraints_dir $result_dir";

    open (my $FILE3, '<', $result_dir) or die "could not open $result_dir : $!\n";
    my $import;
    while (my $line  = <$FILE3>) {
        $import .= $line;
    }
    my $result = JSON->new->utf8->decode($import);

    my $selected_host = $result->{selectedHostIndex};

    unlink ($infra_dir, $constraints_dir, $result_dir);

    if ($selected_host == -1) {
        throw Kanopya::Exception(error => 'HostSelector - getHost : None of the free hosts match the ' . 
                                          'given cluster constraints.');
    }

    return $selected_host;
}
