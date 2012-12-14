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

    General::checkParams(args => \%args, required => [ 'host' ]);

    my $host = $args{host};

    if (defined $args{ram}) {
        if (not $self->_matchRam(host => $args{host}, ram => $args{ram})) {
            return 0;
        }
    }
    if (defined $args{core}) {
        if (not $self->_matchCore(host => $args{host}, core => $args{core})) {
            return 0;
        }
    }
    if (defined $args{interfaces}) {
        if (not $self->_matchIfaceNumber(host => $args{host}, interfaces => $args{interfaces})) {
            return 0;
        }
        if (not $self->_matchIfaceNetconf(host => $args{host}, interfaces => $args{interfaces})) {
            return 0;
        }
    }

    return 1;
}

=pod

=begin classdoc

check iface netconf constraint
If any of the host iface is configured, all the cluster interface must be matched by
at least one of the host iface

@param host
@param interfaces

@return boolean

=end classdoc

=cut

sub _matchIfaceNetconf {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'interfaces' ]);

    my @interfaces = @{ $args{interfaces} };
    my $host = $args{host};

    my @configured_ifaces = $host->configuredIfaces;

    if (scalar @configured_ifaces > 0) {
        my @configured_bonded_ifaces = grep {scalar @{$_->slaves} > 0} @configured_ifaces;
        my @configured_simple_ifaces =
            grep {scalar @{ $_->slaves } == 0 && !$_->master} @configured_ifaces;
        my @configured_simple_interfaces =
            grep {scalar $_->netconfs > 0 && $_->bonds_number == 0} @{ $args{interfaces} };
        my @configured_bonded_interfaces =
            grep {scalar $_->netconfs > 0 && $_->bonds_number > 0} @{ $args{interfaces} };
        my @iface_netconfs;
        my @interface_netconfs;
        my @matching_netconfs;

        #First the bonded interfaces
        if (scalar @configured_bonded_interfaces > 0) {

            BONDED_INTERFACES:
            foreach my $configured_bonded_interface (@configured_bonded_interfaces) {
                my @matchs;
                @interface_netconfs = $configured_bonded_interface->netconfs;
                my @same_bond_nb =
                    grep {$configured_bonded_interface->bonds_number == scalar @{ $_->slaves }}
                    @configured_bonded_ifaces;
                if (!scalar @same_bond_nb) {
                    my $msg = 'The bonded cluster interface <' .$configured_bonded_interface->id;
                    $msg   .= '> does not have any matching iface on host <' . $host->id . '>';
                    $log->debug($msg);
                    return 0;
                }
                foreach my $netconf (@interface_netconfs) {
                    foreach my $configured_bonded_iface (@same_bond_nb) {
                        @iface_netconfs = $configured_bonded_iface->netconfs;
                        @matching_netconfs  = grep {$netconf->id == $_->id} @iface_netconfs;
                        if (scalar @matching_netconfs > 0) {
                            push @matchs, $configured_bonded_iface;
                        }
                    }
                    if (scalar @matchs > 0) {
                        my %retained;
                        $retained{$matchs[0]} = 1;
                        @configured_bonded_ifaces = grep {!$retained{$_}} @configured_bonded_ifaces;
                        next BONDED_INTERFACES;
                    }
                }
                if (!scalar @matchs) {
                    my $msg = 'There is no iface on host <' . $host->id . '> that can match ';
                    $msg   .= ' the configuration of cluster interface <' . $configured_bonded_interface->id;
                    $msg   .= '>';
                    $log->debug($msg);
                    return 0;
                }
            }
        }

        #Then the simple ones
        if (scalar @configured_simple_interfaces > 0) {

            SIMPLE_INTERFACES:
            foreach my $configured_simple_interface (@configured_simple_interfaces) {
                my @matchs;
                @interface_netconfs = $configured_simple_interface->netconfs;
                foreach my $netconf (@interface_netconfs) {
                    foreach my $configured_simple_iface (@configured_simple_ifaces) {
                        @iface_netconfs = $configured_simple_iface->netconfs;
                        @matching_netconfs  = grep {$netconf->id == $_->id} @iface_netconfs;
                        if (scalar @matching_netconfs > 0) {
                            push @matchs, $configured_simple_iface;
                        }
                    }
                    if (scalar @matchs > 0) {
                        my %retained;
                        $retained{$matchs[0]} = 1;
                        @configured_simple_ifaces = grep {!$retained{$_}} @configured_simple_ifaces;
                        next SIMPLE_INTERFACES;
                    }
                }
                if (!scalar @matchs) {
                    my $msg = 'There is no iface on host <' . $host->id . '> that can match ';
                    $msg   .= ' the configuration of cluster interface <' . $configured_simple_interface->id;
                    $msg   .= '>';
                    $log->debug($msg);
                    return 0;
                }
            }
        }
    }
}

=pod

=begin classdoc

check iface number constraint

@param host
@param interfaces

@return boolean

=end classdoc

=cut

sub _matchIfaceNumber {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'interfaces' ]);

    my $host = $args{host};
    my @interfaces = @{ $args{interfaces} };
    my @ifaces = $host->ifaces;

    my $nb_simple_interfaces;
    my @copy_ifaces = @ifaces;
    my @simple_ifaces = grep {!$_->master && scalar @{$_->slaves} == 0} @ifaces;

    foreach my $interface (@interfaces) {
        if ($interface->bonds_number > 0) {
            my @matchs = grep {scalar @{$_->slaves} == $interface->bonds_number} @copy_ifaces;
            if (scalar @matchs != 0) {
                #retain one of the match to delete it from the parsed ifaces
                my %retained;
                $retained{$matchs[0]} = 1;
                @copy_ifaces = grep {!$retained{$_}} @copy_ifaces;
            }
            else {
                $log->info('host ' . $host->id . ' cannot meet the cluster bond requirements');
                return 0;
            }
        }
        else {
            $nb_simple_interfaces++;
        }
    }

    if ($nb_simple_interfaces > scalar @simple_ifaces) {
        my $msg = 'host ' . $host->id . ' does not have enough simple ifaces (';
        $msg   .= scalar @simple_ifaces . ' ) to meet the cluster common interface requirements (';
        $msg   .= $nb_simple_interfaces . ')';
        $log->info($msg);
        return 0;
    }

}

=pod

=begin classdoc

check ram constraint

@param host
@param ram

@return boolean

=end classdoc

=cut

sub _matchRam {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'ram' ]);

   if ($args{host}->host_ram >= $args{ram}) {
        $log->debug('Cluster ram constraint (' . $args{ram} . ') <= host ram amount (' . $args{host}->host_ram . ')');
        return 1;
    }
    else {
        $log->debug('Cluster ram constraint (' . $args{ram} . ') >= host ram amount (' . $args{host}->host_ram . ')');
        return 0;
    }
}

=pod

=begin classdoc

check cores constraint

@param host
@param core

@return boolean

=end classdoc

=cut

sub _matchCore {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'core' ]);

    if ($args{host}->host_core >= $args{core}) {
        $log->debug('Cluster core constraint (' . $args{core} . ') <= host cores number (' . $args{host}->host_core . ')');
        return 1;
    }
    else {
        $log->debug('Cluster core constraint (' . $args{core} . ') >= host cores number (' . $args{host}->host_core . ')');
        return 0;
    }
}

1;
