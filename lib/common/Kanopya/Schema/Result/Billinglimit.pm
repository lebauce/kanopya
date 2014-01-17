use utf8;
package Kanopya::Schema::Result::Billinglimit;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Billinglimit

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

=head1 TABLE: C<billinglimit>

=cut

__PACKAGE__->table("billinglimit");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 start

  data_type: 'bigint'
  is_nullable: 0

=head2 ending

  data_type: 'bigint'
  is_nullable: 0

=head2 type

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 soft

  data_type: 'tinyint'
  is_nullable: 0

=head2 value

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 service_provider_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 repeats

  data_type: 'integer'
  is_nullable: 0

=head2 repeat_day

  data_type: 'integer'
  is_nullable: 0

=head2 repeat_start_time

  data_type: 'bigint'
  is_nullable: 0

=head2 repeat_end_time

  data_type: 'bigint'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "start",
  { data_type => "bigint", is_nullable => 0 },
  "ending",
  { data_type => "bigint", is_nullable => 0 },
  "type",
  { data_type => "char", is_nullable => 0, size => 32 },
  "soft",
  { data_type => "tinyint", is_nullable => 0 },
  "value",
  { data_type => "bigint", extra => { unsigned => 1 }, is_nullable => 1 },
  "service_provider_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "repeats",
  { data_type => "integer", is_nullable => 0 },
  "repeat_day",
  { data_type => "integer", is_nullable => 0 },
  "repeat_start_time",
  { data_type => "bigint", is_nullable => 0 },
  "repeat_end_time",
  { data_type => "bigint", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 id

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "id",
  "Kanopya::Schema::Result::Entity",
  { entity_id => "id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 service_provider

Type: belongs_to

Related object: L<Kanopya::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "service_provider",
  "Kanopya::Schema::Result::ServiceProvider",
  { service_provider_id => "service_provider_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XYvPuARxQchZvDYGJWx7Xg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
