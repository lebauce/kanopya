#    Copyright © 2014 Hedera Technology SAS
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

Implement Openstack API Compute operations related to ports

=end classdoc
=cut

package OpenStack::Port;

use strict;
use warnings;

use General;


=pod
=begin classdoc

Lists all available ports (i.e. vms)

=end classdoc
=cut

sub list {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => [ 'api' ]);
    return $args{api}->network->ports->get->{ports};
}


=pod
=begin classdoc

Create a new port

=end classdoc
=cut

sub create {
    my ($class, %args) = @_;
    General::checkParams(
        args => \%args,
        required => [ 'api', 'ip_address', 'network_id', 'subnet_id' ],
        optional => {name => undef, mac_address => undef},
    );

    my $params = {
        port => {
            fixed_ips => [{
                ip_address => $args{ip_address},
                subnet_id => $args{subnet_id},
            }],
            network_id => $args{network_id},
        }
    };

    if (defined $args{name}) {
        $params->{port}->{name} = $args{name};
    }

    if (defined $args{mac_address}) {
        $params->{port}->{mac_address} = $args{mac_address},
    }

    my $response = $args{api}->network->ports->post(
        content => $params
    );

    return $response->{port};
}
1;