use utf8;
package Kanopya::Schema::Result::Anomaly;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Anomaly

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

=head1 TABLE: C<anomaly>

=cut

__PACKAGE__->table("anomaly");

=head1 ACCESSORS

=head2 anomaly_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 related_metric_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "anomaly_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "related_metric_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</anomaly_id>

=back

=cut

__PACKAGE__->set_primary_key("anomaly_id");

=head1 RELATIONS

=head2 anomaly

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Metric>

=cut

__PACKAGE__->belongs_to(
  "anomaly",
  "Kanopya::Schema::Result::Metric",
  { metric_id => "anomaly_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 related_metric

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Metric>

=cut

__PACKAGE__->belongs_to(
  "related_metric",
  "Kanopya::Schema::Result::Metric",
  { metric_id => "related_metric_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-04-17 12:34:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fdMM2mr1eglTIIf4LJeKHQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
