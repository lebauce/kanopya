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

package DecisionMaker::HostSelector;

use strict;
use warnings;

use General;
use Entity;
use Entity::Host;
use Kanopya::Exceptions;

use Data::Dumper;
use Log::Log4perl "get_logger";

my $log = get_logger("");

=pod

=begin classdoc

Select and return the more suitable host according to constraints

All constraints args are optional, not defined means no constraint for this arg
Final constraints are intersection of input constraints and cluster components contraints.

@optional core min number of desired core
@optional ram  min amount of desired ram  # TODO manage unit (M,G,..)

@return Entity::Host

=end classdoc

=cut

sub getHost {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "host_manager_id" ],
                                         optional => { ram  => 512 * 1024 * 1024,
                                                       core => 1 });

    $log->debug("Host selector search for a node with ram : <$args{ram}> and core : <$args{core}>");

    # Get all free hosts of the specified host manager
    my $host_manager = Entity->get(id => $args{host_manager_id});
    my @free_hosts = $host_manager->getFreeHosts();

    # Keep only hosts matching constraints (cpu, mem, interfaces)
    my @valid_hosts = grep { $self->_matchHostConstraints(host => $_, %args) } @free_hosts;

    if (scalar @valid_hosts == 0) {
        my $errmsg = "no free host respecting constraints";
        $log->warn($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    # Get the first valid host
    # TODO get the better hosts according to rank (e.g min consumption, max cpu, ...)
    my $host = $valid_hosts[0];

    return $host;
}

=pod

=begin classdoc

Filter the hosts with the given contraints

@param host
@optional ram
@optional cpu
@optional ifaces a number of interfaces

@return boolean

=end classdoc

=cut

sub _matchHostConstraints {
    my ($self,%args)  = @_;

    General::checkParams(args => \%args, required => [ "host" ]);

    my $host = $args{host};

    for my $constraint ('core', 'ram') {
        if (defined $args{$constraint}) {
            my $host_value = $host->getAttr(name => "host_$constraint");
            $log->debug("constraint '$constraint' ($host_value) >= $args{$constraint}");
            if ($host_value < $args{$constraint}) {
                return 0;
            }
        }
    }

    if (defined $args{interfaces}) {
        my @ifaces = $host->ifaces;
        my $nb_ifaces = scalar(@ifaces);

        #We gather the number of interfaces that has to be available from the host
        #Plus we check if the bonded iface meet the bonded interfaces slaves requirements
        my $nb_common_interfaces;
        my @copy_ifaces = @ifaces;
        my @common_ifaces = grep {!$_->master && scalar @{$_->slaves} == 0} @ifaces;

        foreach my $interface (@{ $args{interfaces} }) {
            if ($interface->bonds_number > 0) {
                my @matchs = grep {scalar @{$_->slaves} == $interface->bonds_number} @copy_ifaces;
                if (scalar @matchs != 0) {
                    #retain one of the match to delete it from the parsed ifaces
                    my %retained;
                    $retained{$matchs[0]} = 1;
                    @copy_ifaces = grep {!$retained{$_}} @copy_ifaces;
                }
                else {
                    $log->info('host ' .$host->id. ' cannot meet the cluster bond requirements');
                    return 0;
                }
            }
            else {
                $nb_common_interfaces++;
            }
        }

        if ($nb_common_interfaces > scalar @common_ifaces) {
            my $msg = 'host ' .$host->id. ' does not have enough common ifaces (' . scalar @common_ifaces;
            $msg   .= ' ) to meet the cluster common interface requirements (' .$nb_common_interfaces. ')';
            $log->info($msg);
            return 0;
        }

        #Does any of the host's iface has a netconf?
        #At least one of the cluster's interface must have the same netconf
        my @configured_ifaces = $host->configuredIfaces;
        if (scalar @configured_ifaces > 0) {
            foreach my $configured_iface (@configured_ifaces) {
                my $configured_interface_netconfs = $configured_iface->netconfs;
                my @matchs;
                foreach my $netconf (@$configured_interface_netconfs) {
                    push @matchs, grep {$netconf->id == $_->netconf->id} @{ $args{interface} };
                }
                if (scalar @matchs == 0) {
                    my $msg = 'There is no cluster interface sharing any of iface ';
                    $msg   .= $configured_iface->id . ' netconf';
                    $log->info($msg);
                    return 0;
                }
            }
        }
    }

    return 1;
}

1;
