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

Implement Openstack API Compute operations related to tenants
http://docs.openstack.org/api/openstack-identity-service/2.0/content/Tenant_Operations.html

=end classdoc
=cut

package OpenStack::Tenant;

use strict;
use warnings;

sub list {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'api' ], optional => {all_tenants => 0});
    return $args{api}->identity->tenants->get(admin => $args{all_tenants})->{tenants};
}

sub detail {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'api', 'id' ]);
    my $route = 'os-simple-tenant-usage';
    my $id = $args{id};
    return $args{api}->compute->$route->$id->get->{tenant_usage};
}
1;