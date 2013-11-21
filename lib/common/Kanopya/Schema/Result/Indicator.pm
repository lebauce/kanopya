use utf8;
package Kanopya::Schema::Result::Indicator;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Indicator

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

=head1 TABLE: C<indicator>

=cut

__PACKAGE__->table("indicator");

=head1 ACCESSORS

=head2 indicator_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 indicator_label

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 indicator_name

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 indicator_oid

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 indicator_min

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 indicator_max

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 indicator_color

  data_type: 'char'
  is_nullable: 1
  size: 8

=head2 indicatorset_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 indicator_unit

  data_type: 'char'
  is_nullable: 1
  size: 32

=head2 service_provider_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "indicator_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "indicator_label",
  { data_type => "char", is_nullable => 0, size => 64 },
  "indicator_name",
  { data_type => "char", is_nullable => 0, size => 64 },
  "indicator_oid",
  { data_type => "char", is_nullable => 0, size => 64 },
  "indicator_min",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "indicator_max",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "indicator_color",
  { data_type => "char", is_nullable => 1, size => 8 },
  "indicatorset_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "indicator_unit",
  { data_type => "char", is_nullable => 1, size => 32 },
  "service_provider_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</indicator_id>

=back

=cut

__PACKAGE__->set_primary_key("indicator_id");

=head1 RELATIONS

=head2 collector_indicators

Type: has_many

Related object: L<Kanopya::Schema::Result::CollectorIndicator>

=cut

__PACKAGE__->has_many(
  "collector_indicators",
  "Kanopya::Schema::Result::CollectorIndicator",
  { "foreign.indicator_id" => "self.indicator_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 indicator

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "indicator",
  "Kanopya::Schema::Result::Entity",
  { entity_id => "indicator_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 indicatorset

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Indicatorset>

=cut

__PACKAGE__->belongs_to(
  "indicatorset",
  "Kanopya::Schema::Result::Indicatorset",
  { indicatorset_id => "indicatorset_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 service_provider

Type: belongs_to

Related object: L<Kanopya::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "service_provider",
  "Kanopya::Schema::Result::ServiceProvider",
  { service_provider_id => "service_provider_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7gHUKZCx8wCJs2QTF8B+Lw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
