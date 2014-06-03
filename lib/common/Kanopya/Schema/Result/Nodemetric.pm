use utf8;
package Kanopya::Schema::Result::Nodemetric;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Nodemetric

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

=head1 TABLE: C<nodemetric>

=cut

__PACKAGE__->table("nodemetric");

=head1 ACCESSORS

=head2 nodemetric_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 nodemetric_label

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 nodemetric_node_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 nodemetric_indicator_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "nodemetric_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "nodemetric_label",
  { data_type => "char", is_nullable => 1, size => 255 },
  "nodemetric_node_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "nodemetric_indicator_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</nodemetric_id>

=back

=cut

__PACKAGE__->set_primary_key("nodemetric_id");

=head1 RELATIONS

=head2 nodemetric

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Metric>

=cut

__PACKAGE__->belongs_to(
  "nodemetric",
  "Kanopya::Schema::Result::Metric",
  { metric_id => "nodemetric_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 nodemetric_indicator

Type: belongs_to

Related object: L<Kanopya::Schema::Result::CollectorIndicator>

=cut

__PACKAGE__->belongs_to(
  "nodemetric_indicator",
  "Kanopya::Schema::Result::CollectorIndicator",
  { collector_indicator_id => "nodemetric_indicator_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 nodemetric_node

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Node>

=cut

__PACKAGE__->belongs_to(
  "nodemetric_node",
  "Kanopya::Schema::Result::Node",
  { node_id => "nodemetric_node_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-05-30 11:56:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XwvY5ZDAol9FKvjXHnISxg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
