#    Copyright © 2013 Hedera Technology SAS
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

package EEntity::EComponent::EOpenstack::ECinder;
use base "EEntity::EComponent";
use base "EManager::EDiskManager";

use strict;
use warnings;

use EEntity;

=head

=begin classdoc
Instruct a cinder instance to create a volume, then trigger the Cinder entity to register
it into Kanopya

@param name the volume name
@param size the volume size

@return a container object

=end classdoc

=cut

sub createDisk {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ "name", "size" ]); 

    my $e_controller = EEntity->new(entity => $self->nova_controller);
    my $api = $e_controller->api;

    my $req = $api->tenant(id => $api->{tenant_id})->volumes->post(
                  target  => 'volume',
                  content => {
                      "volume" => {
                          "name"         => $args{name},
                          "size"         => $args{size} / 1024 / 1024 / 1024,
                          "display_name" => $args{name},
                      }
                  }
              );

    my $entity = $self->lvcreate(
                     volume_id    => $req->{volume}->{id},
                     lvm2_lv_name => $args{name},
                     lvm2_lv_size => $args{size} / 1024 / 1024 / 1024,
                 );

    my $container = EEntity->new(data => $entity);

    return $container;
}

1;
