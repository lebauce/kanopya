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

Implement Openstack API Voulme operations related to volume types

=end classdoc
=cut

package OpenStack::VolumeType;

use strict;
use warnings;

use General;

=pod

=begin classdoc

Lists all available volume types

=end classdoc
=cut

sub list {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => [ 'api' ], );
    return $args{api}->volume->types->get->{volume_types};
}

sub detail {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => [ 'api', 'id' ]);
    return $args{api}->volume->types(id => $args{id})->get->{volume_type};
}

1;