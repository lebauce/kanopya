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

Implement Openstack API Compute operations related to hypervisors
http://docs.openstack.org/api/openstack-compute/2/content/ext-os-hypervisors.html

=end classdoc
=cut

package OpenStack::Infrastructure;

use OpenStack::Hypervisor;
use OpenStack::Server;
use OpenStack::Image;
use OpenStack::Volume;
use OpenStack::Flavor;
use OpenStack::Tenant;
use OpenStack::Network;
use OpenStack::Zone;
use OpenStack::VolumeType;

sub load {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => [ 'api' ]);

    my $hypervisors = OpenStack::Hypervisor->detailList(%args);
    for my $hypervisor (@$hypervisors) {
        my $vms = OpenStack::Hypervisor->servers(%args, id => $hypervisor->{id});
        my @vm_details = ();
        for my $vm (@$vms) {
            my $detail = OpenStack::Server->detail(%args, id => $vm->{uuid}, flavor_detail => 1);
            push @vm_details, $detail->{server};
        }
        $hypervisor->{servers} = \@vm_details;
    }

    return {
        'hypervisors' => $hypervisors,
        'images' => OpenStack::Image->list(%args)->{images},
        'volumes' => OpenStack::Volume->list(%args, all_tenants => 1),
        'volume_types' => OpenStack::VolumeType->list(%args),
        'tenants' => OpenStack::Tenant->list(%args, all_tenants => 1),
        'flavors' => OpenStack::Flavor->list(%args),
        'networks' => OpenStack::Network->list(%args),
        'availability_zones' => OpenStack::Zone->list(%args),
        'subnets' => OpenStack::Subnet->list(%args),
    }
}

1;