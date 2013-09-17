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
use File::Temp qw(tempfile);;

use General;
use EContext::Local;
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

@param cluster The cluster containing all the constraints, and a reference to the free hosts list.

@return the selected host

=end classdoc
=cut

sub getHost {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, required => [ "cluster" ]);

    $log->debug('HostSelector : Retrieving cluster params');

    my $cluster      = $args{cluster};
    my $host_params  = $cluster->getManagerParameters(manager_type => "HostManager");

    $log->debug('HostSelector : Retrieving free hosts');

    my $host_manager = $cluster->getManager(manager_type => "HostManager");
    my @free_hosts   = $host_manager->getFreeHosts();

    $log->debug('HostSelector : Number of free hosts in the host manager : ' . scalar(@free_hosts));

    $log->debug('HostSelector : Retrieving id of master network to exclude it from the constraints');

    my $admin_id     = Entity::Network->find(hash => { network_name => "admin" })->id;

    # Generate Json objects for the external module (infrastructure and constraints)

    $log->debug('HostSelector : Creating JSON structure for hosts description');

    # INFRASTRUCTURE
    my @json_infrastructure;
    for my $host (@free_hosts) {

        # Construct json ifaces (bonds number + netIPs)
        my @json_ifaces;
        for my $iface (@{ $host->getIfaces() }) {
            my @netconfs = $iface->netconfs;
            my @temp_networks;
            for my $netconf (@netconfs) {
                # Add id of all networks in the current netconf
                @temp_networks = (@temp_networks, map { $_->network->id } $netconf->poolips);
            }
            # Don't keep id of the admin network
            my @networks;
            for my $network_id (@temp_networks) {
                if ($network_id != $admin_id) {
                    push @networks, $network_id;
                }
            }
            my $json_iface = {
                bondsNumber => scalar(@{ $iface->slaves }) + 1,
                netIPs    => \@networks,
            };
            push @json_ifaces, $json_iface;
        }
        # Construct hard disks structure
        my @hard_disks;
        for my $harddisk ($host->harddisks) {
            push @hard_disks, { size => $harddisk->harddisk_size/1024/1024/1024 };
        }
        # Construct the current host
        my @tags = map { $_->id } $host->tags;
        my $current = {
            cpu     => {
                nbCores   => $host->host_core,
            },
            ram     => {
                qty       => $host->host_ram/1024/1024,
            },
            network => {
                ifaces    => \@json_ifaces,
            },
            storage => {
                hardDisks => \@hard_disks,
            },
            tags => \@tags,
        };

        push @json_infrastructure, $current;
    }

    $log->debug('HostSelector : Creating JSON structure for constraints description');

    # CLUSTER CONSTRAINTS

    # Construct json interfaces (bonds number + netIPs)
    my @json_interfaces;
    for my $interface ($cluster->interfaces) {
        my @netconfs = $interface->netconfs;
        my @temp_networks;
        for my $netconf (@netconfs) {
            # Add id of all networks in the current netconf
            @temp_networks = (@temp_networks, map { $_->network->id } $netconf->poolips);
        }
        # Don't keep id of the admin network
        my @networks;
        for my $network_id (@temp_networks) {
            if ($network_id != $admin_id) {
                push @networks, $network_id;
            }
        }
        my $json_interface = {
            bondsNumberMin => $interface->bonds_number + 1,
            netIPsMin      => \@networks,
        };
        push @json_interfaces, $json_interface;
    }

    # Construct the constraint json object

    my $json_constraints = {
        cpu      => {
            nbCoresMin         => $host_params->{core},
        },
        ram      => {
            qtyMin             => $host_params->{ram}/1024/1024,
        },
        network  => {
            interfaces         => \@json_interfaces,
        },
        storage  => {
            hardDisksNumberMin => $host_params->{deploy_on_disk} ? 1 : 0,
        },
        tagsMin  => defined( $host_params->{tags} ) ? $host_params->{tags} : [],
        noTags   => defined( $host_params->{no_tags} ) ? $host_params->{no_tags} : [],
    };

    $log->debug('HostSelector : Creating JSON temp files');

    # Create temp files
    (my $infra_file, my $infra_filename)             = tempfile("hosts.jsonXXXXX", TMPDIR => 1);
    (my $constraints_file, my $constraints_filename) = tempfile("constraints.jsonXXXXX", TMPDIR => 1);
    (my $result_file, my $result_filename)           = tempfile("result.jsonXXXXX", TMPDIR => 1);

    # Write generated Json's into
    my $hosts_json = JSON->new->utf8->encode(\@json_infrastructure);
    print $infra_file $hosts_json;

    my $constraints_json = JSON->new->utf8->encode($json_constraints);
    print $constraints_file $constraints_json;

    $log->debug($constraints_json);

    my $jar = Kanopya::Config->getKanopyaDir() . JAR_DIR . JAR_NAME;

    $log->debug('HostSelector : Calling the Jar:');

    my $econtext = EContext::Local->new();
    my $command  = "java -jar $jar $infra_filename $constraints_filename $result_filename";
    my $result   = $econtext->execute(command => $command);
    if ($result->{stderr} and ($result->{exitcode} != 0)) {
        throw Kanopya::Exception(error => $result->{stderr});
    }
    $log->debug($command);
    $log->debug('HostSelector : Retrieving the result and unlink the files');

    my $import;
    while (my $line  = <$result_file>) {
        $import .= $line;
    }
    $result = JSON->new->utf8->decode($import);

    my $selected_host = $result->{selectedHostIndex};

    my $log_message = "";
    if ( defined($result->{contradictions}) ) {
        $log_message = "The following contradictions had been found :\n";
        my @contradictions = @{ $result->{contradictions} };
        for my $contradiction (@contradictions) {
            $log_message = $log_message . "    $contradiction\n";
        }
        $log->debug('HostSelector : No host could be found. ' . $log_message);
    }

    unlink $infra_filename;
    unlink $constraints_filename;
    unlink $result_filename;

    if ($selected_host == -1) {
        throw Kanopya::Exception(error => 'HostSelector - getHost : None of the free hosts match the ' . 
                                          'given cluster constraints.\n' . $log_message);
    }

    return $free_hosts[$selected_host];
}

1;
