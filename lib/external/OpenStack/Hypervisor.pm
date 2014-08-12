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

package OpenStack::Hypervisor;

use strict;
use warnings;

use General;

my $os_hypervisors = 'os-hypervisors';


=pod
=begin classdoc

Lists hypervisors information for each server obtained through
the hypervisor-specific API, such as libvirt or XenAPI.

=end classdoc
=cut

sub list {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => [ 'api' ]);
    return $args{api}->compute->$os_hypervisors->get->{hypervisors};
}


=pod
=begin classdoc

Shows information for a specified hypervisor. Typically configured
as an admin-only extension by using policy.json settings.

=end classdoc
=cut

sub detailList {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => [ 'api' ]);
    return $args{api}->compute->$os_hypervisors->detail->get->{hypervisors};
}


=pod
=begin classdoc

Shows details of a specified hypervisor.

=end classdoc
=cut

sub detail {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => [ 'api', 'id']);
    my $id = $args{id};
    return $args{api}->compute->$os_hypervisors->$id->get->{hypervisor};
}


=pod
=begin classdoc

Lists vm instances that belong to specific hypervisors.

=end classdoc
=cut

sub servers {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => [ 'api', 'id']);
    my $id = $args{id};
    # TODO Check if ok in infra with 2 HV
    return $args{api}->compute->$os_hypervisors->$id->servers->get->{hypervisors}->[0]->{servers};
}

1;