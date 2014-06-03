use utf8;
package Kanopya::Schema::Result::CollectorIndicator;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::CollectorIndicator

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

=head1 TABLE: C<collector_indicator>

=cut

__PACKAGE__->table("collector_indicator");

=head1 ACCESSORS

=head2 collector_indicator_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 indicator_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 collector_manager_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "collector_indicator_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "indicator_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "collector_manager_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</collector_indicator_id>

=back

=cut

__PACKAGE__->set_primary_key("collector_indicator_id");

=head1 RELATIONS

=head2 clustermetrics

Type: has_many

Related object: L<Kanopya::Schema::Result::Clustermetric>

=cut

__PACKAGE__->has_many(
  "clustermetrics",
  "Kanopya::Schema::Result::Clustermetric",
  {
    "foreign.clustermetric_indicator_id" => "self.collector_indicator_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 collector_indicator

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "collector_indicator",
  "Kanopya::Schema::Result::Entity",
  { entity_id => "collector_indicator_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 collector_manager

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "collector_manager",
  "Kanopya::Schema::Result::Component",
  { component_id => "collector_manager_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 indicator

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Indicator>

=cut

__PACKAGE__->belongs_to(
  "indicator",
  "Kanopya::Schema::Result::Indicator",
  { indicator_id => "indicator_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 nodemetrics

Type: has_many

Related object: L<Kanopya::Schema::Result::Nodemetric>

=cut

__PACKAGE__->has_many(
  "nodemetrics",
  "Kanopya::Schema::Result::Nodemetric",
  {
    "foreign.nodemetric_indicator_id" => "self.collector_indicator_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-05-30 11:56:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LPBsFmXWIrD8ip5q76vndQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
