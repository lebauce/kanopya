use utf8;
package Kanopya::Schema::Result::KanopyaAnomalyDetector;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::KanopyaAnomalyDetector

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

=head1 TABLE: C<kanopya_anomaly_detector>

=cut

__PACKAGE__->table("kanopya_anomaly_detector");

=head1 ACCESSORS

=head2 kanopya_anomaly_detector_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 control_queue

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 time_step

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 storage_duration

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "kanopya_anomaly_detector_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "control_queue",
  { data_type => "char", is_nullable => 1, size => 255 },
  "time_step",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "storage_duration",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</kanopya_anomaly_detector_id>

=back

=cut

__PACKAGE__->set_primary_key("kanopya_anomaly_detector_id");

=head1 RELATIONS

=head2 kanopya_anomaly_detector

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "kanopya_anomaly_detector",
  "Kanopya::Schema::Result::Component",
  { component_id => "kanopya_anomaly_detector_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-04-09 11:35:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hGvDMGUvnh5Is2+gPeBJmg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
