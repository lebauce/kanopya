use utf8;
package Kanopya::Schema::Result::Indicatorset;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Indicatorset

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

=head1 TABLE: C<indicatorset>

=cut

__PACKAGE__->table("indicatorset");

=head1 ACCESSORS

=head2 indicatorset_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 indicatorset_name

  data_type: 'char'
  is_nullable: 0
  size: 16

=head2 indicatorset_provider

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 indicatorset_type

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 indicatorset_component

  data_type: 'char'
  is_nullable: 1
  size: 32

=head2 indicatorset_max

  data_type: 'char'
  is_nullable: 1
  size: 128

=head2 indicatorset_tableoid

  data_type: 'char'
  is_nullable: 1
  size: 64

=head2 indicatorset_indexoid

  data_type: 'char'
  is_nullable: 1
  size: 64

=cut

__PACKAGE__->add_columns(
  "indicatorset_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "indicatorset_name",
  { data_type => "char", is_nullable => 0, size => 16 },
  "indicatorset_provider",
  { data_type => "char", is_nullable => 0, size => 32 },
  "indicatorset_type",
  { data_type => "char", is_nullable => 0, size => 32 },
  "indicatorset_component",
  { data_type => "char", is_nullable => 1, size => 32 },
  "indicatorset_max",
  { data_type => "char", is_nullable => 1, size => 128 },
  "indicatorset_tableoid",
  { data_type => "char", is_nullable => 1, size => 64 },
  "indicatorset_indexoid",
  { data_type => "char", is_nullable => 1, size => 64 },
);

=head1 PRIMARY KEY

=over 4

=item * L</indicatorset_id>

=back

=cut

__PACKAGE__->set_primary_key("indicatorset_id");

=head1 RELATIONS

=head2 collects

Type: has_many

Related object: L<Kanopya::Schema::Result::Collect>

=cut

__PACKAGE__->has_many(
  "collects",
  "Kanopya::Schema::Result::Collect",
  { "foreign.indicatorset_id" => "self.indicatorset_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 indicators

Type: has_many

Related object: L<Kanopya::Schema::Result::Indicator>

=cut

__PACKAGE__->has_many(
  "indicators",
  "Kanopya::Schema::Result::Indicator",
  { "foreign.indicatorset_id" => "self.indicatorset_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_providers

Type: many_to_many

Composing rels: L</collects> -> service_provider

=cut

__PACKAGE__->many_to_many("service_providers", "collects", "service_provider");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eKszehRq4dPREdTkry12KA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
