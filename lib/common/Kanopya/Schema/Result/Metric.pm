use utf8;
package Kanopya::Schema::Result::Metric;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Metric

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

=head1 TABLE: C<metric>

=cut

__PACKAGE__->table("metric");

=head1 ACCESSORS

=head2 metric_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 param_preset_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "metric_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "param_preset_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</metric_id>

=back

=cut

__PACKAGE__->set_primary_key("metric_id");

=head1 RELATIONS

=head2 anomaly_anomaly

Type: might_have

Related object: L<Kanopya::Schema::Result::Anomaly>

=cut

__PACKAGE__->might_have(
  "anomaly_anomaly",
  "Kanopya::Schema::Result::Anomaly",
  { "foreign.anomaly_id" => "self.metric_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 anomaly_related_metrics

Type: has_many

Related object: L<Kanopya::Schema::Result::Anomaly>

=cut

__PACKAGE__->has_many(
  "anomaly_related_metrics",
  "Kanopya::Schema::Result::Anomaly",
  { "foreign.related_metric_id" => "self.metric_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 clustermetric

Type: might_have

Related object: L<Kanopya::Schema::Result::Clustermetric>

=cut

__PACKAGE__->might_have(
  "clustermetric",
  "Kanopya::Schema::Result::Clustermetric",
  { "foreign.clustermetric_id" => "self.metric_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 combination

Type: might_have

Related object: L<Kanopya::Schema::Result::Combination>

=cut

__PACKAGE__->might_have(
  "combination",
  "Kanopya::Schema::Result::Combination",
  { "foreign.combination_id" => "self.metric_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 metric

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "metric",
  "Kanopya::Schema::Result::Entity",
  { entity_id => "metric_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 param_preset

Type: belongs_to

Related object: L<Kanopya::Schema::Result::ParamPreset>

=cut

__PACKAGE__->belongs_to(
  "param_preset",
  "Kanopya::Schema::Result::ParamPreset",
  { param_preset_id => "param_preset_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-04-17 12:34:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zLHzF/5/LtG/tgJK4I2yMg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
