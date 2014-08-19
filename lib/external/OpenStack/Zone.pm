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

Implement Openstack API Compute operations related to availability zones

=end classdoc
=cut

package OpenStack::Zone;

use strict;
use warnings;

use General;

=pod
=begin classdoc

Lists all available availability zones

=end classdoc
=cut

sub list {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => [ 'api' ],);
    my $route = 'os-availability-zone';
    return $args{api}->compute->$route->get->{availabilityZoneInfo};
}

1;