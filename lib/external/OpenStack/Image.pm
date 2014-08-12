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

Implement Openstack API Compute operations related to Images
http://docs.openstack.org/api/openstack-compute/2/content/List_Images-d1e4435.html

=end classdoc
=cut

package OpenStack::Image;

use strict;
use warnings;

use General;

=pod

=begin classdoc

Lists all available images

=end classdoc
=cut

sub list {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => [ 'api' ]);
    my $images_and_snap = $args{api}->image->images->get->{images};
    my @images = ();
    my @snaps = ();

    for my $image_info (@$images_and_snap) {
        if (defined $image_info->{'image_name'}) {
            push @snaps, $image_info;
        }
        else {
            push @images, $image_info;
        }
    }
    return {
        images => \@images,
        snapshots => \@snaps,
    }
}

1;