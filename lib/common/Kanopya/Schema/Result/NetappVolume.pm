use utf8;
package Kanopya::Schema::Result::NetappVolume;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::NetappVolume

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<DBIx::Class::IntrospectableM2M>

=cut

use base 'DBIx::Class::IntrospectableM2M';

=head1 LEFT BASE CLASSES

=over 4

=item * L<DBIx::Class::Core>

=back

=cut

use base qw/DBIx::Class::Core/;

=head1 TABLE: C<netapp_volume>

=cut

__PACKAGE__->table("netapp_volume");

=head1 ACCESSORS

=head2 volume_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 aggregate_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "volume_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "aggregate_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</volume_id>

=back

=cut

__PACKAGE__->set_primary_key("volume_id");

=head1 RELATIONS

=head2 aggregate

Type: belongs_to

Related object: L<Kanopya::Schema::Result::NetappAggregate>

=cut

__PACKAGE__->belongs_to(
  "aggregate",
  "Kanopya::Schema::Result::NetappAggregate",
  { aggregate_id => "aggregate_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 netapp_luns

Type: has_many

Related object: L<Kanopya::Schema::Result::NetappLun>

=cut

__PACKAGE__->has_many(
  "netapp_luns",
  "Kanopya::Schema::Result::NetappLun",
  { "foreign.volume_id" => "self.volume_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 volume

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Container>

=cut

__PACKAGE__->belongs_to(
  "volume",
  "Kanopya::Schema::Result::Container",
  { container_id => "volume_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3n8szRwzu/EHUF2VMdDY+Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
