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

Implement Openstack API Compute operations related to servers (virtual machines)
http://docs.openstack.org/api/openstack-compute/2/content/compute_servers.html

=end classdoc
=cut

package OpenStack::Server;

use strict;
use warnings;

use General;
use OpenStack::Flavor;

=pod
=begin classdoc

Lists all available servers (i.e. vms)

=end classdoc
=cut

sub list {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => [ 'api' ], optional => {all_tenants => 0});

    if ($args{all_tenants} eq 1) {
        my $option = 'detail?all_tenants=True';
        return $args{api}->compute->servers->$option->get->{servers};
    }

    return $args{api}->compute->servers->get->{servers};
}


=pod
=begin classdoc

Details of a specified server (i.e. vms)

=end classdoc
=cut

sub detail {
    my ($class, %args) = @_;
    General::checkParams(
        args => \%args,
        required => [ 'api', 'id' ],
        optional => {flavor_detail => 0},
    );

    my $vm_detail = $args{api}->compute->servers(id => $args{id})->get->{server};

    if ($args{flavor_detail} eq 1) {
        my $flavor_detail = OpenStack::Flavor->detail(
                                id => $vm_detail->{flavor}->{id},
                                api => $args{api},
                            );

        $vm_detail->{flavor} = $flavor_detail;
    }

    return $vm_detail;
}

1;