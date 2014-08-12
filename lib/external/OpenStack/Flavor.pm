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

Implement Openstack API Compute operations related to flavors
http://docs.openstack.org/api/openstack-compute/2/content/Flavors-d1e4180.html

=end classdoc
=cut

package OpenStack::Flavor;

use strict;
use warnings;

use General;


=pod
=begin classdoc

Lists all available flavors.

=end classdoc
=cut

sub list {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => [ 'api' ]);
    return $args{api}->compute->flavors->detail->get->{flavors};
}


=pod
=begin classdoc

Gets details for a specified flavor.

=end classdoc
=cut

sub detail {
    my ($class, %args) = @_;
	General::checkParams(args => \%args, required => [ 'api', 'id' ]);
    return $args{api}->compute->flavors(id => $args{id})->get->{flavor};
}



1;