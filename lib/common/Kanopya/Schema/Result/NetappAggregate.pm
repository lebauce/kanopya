use utf8;
package Kanopya::Schema::Result::NetappAggregate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::NetappAggregate

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

=head1 TABLE: C<netapp_aggregate>

=cut

__PACKAGE__->table("netapp_aggregate");

=head1 ACCESSORS

=head2 aggregate_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 netapp_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "aggregate_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "char", is_nullable => 0, size => 255 },
  "netapp_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</aggregate_id>

=back

=cut

__PACKAGE__->set_primary_key("aggregate_id");

=head1 RELATIONS

=head2 aggregate

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "aggregate",
  "Kanopya::Schema::Result::Entity",
  { entity_id => "aggregate_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 netapp

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Netapp>

=cut

__PACKAGE__->belongs_to(
  "netapp",
  "Kanopya::Schema::Result::Netapp",
  { netapp_id => "netapp_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 netapp_volumes

Type: has_many

Related object: L<Kanopya::Schema::Result::NetappVolume>

=cut

__PACKAGE__->has_many(
  "netapp_volumes",
  "Kanopya::Schema::Result::NetappVolume",
  { "foreign.aggregate_id" => "self.aggregate_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/iENGyvFVFNAh2IL0Aiapg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
