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

my $log = get_logger("administrator");

=head2 getHost

    Class : Public

    Desc :  Select and return the more suitable host according to constraints

    Args :  core : min number of desired core
            ram  : min amount of desired ram  # TODO manage unit (M,G,..)

            All constraints args are optional, not defined means no constraint for this arg
            Final constraints are intersection of input constraints and cluster components contraints.

    Return : Entity::Host

=cut

sub getHost {
    my $self = shift;
    my %args = @_;
    my ($default_core, $default_ram) = (1, "512M");

    General::checkParams(args => \%args, required => [ "host_manager_id" ]);

    # Set default Ram and convert in B.
    my $ram = defined $args{ram} ? $args{ram} : $default_ram;
    my ($value, $unit) = General::convertSizeFormat(size => $ram);
    $args{ram} = General::convertToBytes(value => $value, units => $unit);

    # Set default core
    $args{core} = $default_core if (not defined $args{core});

    $log->debug("Host selector search for a node with ram : <$args{ram}> and core : <$args{core}>");

    # Get all free hosts of the specified host manager
    my $host_manager = Entity->get(id => $args{host_manager_id});
    my @free_hosts = $host_manager->getFreeHosts();

    # Keep only hosts matching constraints (cpu, mem)
    my @valid_hosts = grep { $self->_matchHostConstraints(host => $_, %args) } @free_hosts;

    if (scalar @valid_hosts == 0) {
        my $errmsg = "no free host respecting constraints";
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    # Get the first valid host
    # TODO get the better hosts according to rank (e.g min consumption, max cpu, ...)
    my $host = $valid_hosts[0];

    return $host;
}

sub _matchHostConstraints {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "host" ]);

    my $host = $args{host};

    for my $constraint ('core', 'ram') {
        if (defined $args{$constraint}) {
            my $host_value = $host->getAttr(name => "host_$constraint");
            $log->info("constraint '$constraint' ($host_value) >= $args{$constraint}");
            if ($host_value < $args{$constraint}) {
                return 0;
            }
        }
    }

    if (defined $args{ifaces}) {
        my @ifaces = $host->getIfaces();
        my $nb_ifaces = scalar(@ifaces);
        if ($args{ifaces} > $nb_ifaces) {
            $log->info("constraint 'ifaces' ($nb_ifaces) >= $args{ifaces}");
            return 0;
        }
    }

    return 1;
}

1;
