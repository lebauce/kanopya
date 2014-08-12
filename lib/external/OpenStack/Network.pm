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

Implement Openstack API Compute operations related to networks

=end classdoc
=cut

package OpenStack::Network;

use OpenStack::Subnet;
use strict;
use warnings;

use General;

=pod

=begin classdoc

Lists all available networks

=end classdoc
=cut


sub list {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => [ 'api' ], optional => {subnets => 0});

    my $list = $args{api}->network->networks->get->{networks};

    # for $i (@$l) { for my $ip (@{$i->{subnets}}) { print $ip} }
    if ($args{subnets} eq 1) {
        for my $network (@$list) {
            my @subnet_list = ();
            for my $id (@{$network->{subnets}}) {
                # TODO Optimisation avoiding calling twice the same route
                push @subnet_list, OpenStack::Subnet->detail(api => $args{api}, id => $id);
            }
            $network->{subnets} = \@subnet_list;
        }
    }

    return $list;
}

sub detail {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => [ 'api', 'id' ]);
    return $args{api}->network->networks(id => $args{id})->get->{network};
}

1;