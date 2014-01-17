use utf8;
package Kanopya::Schema::Result::WorkloadCharacteristic;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::WorkloadCharacteristic

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

=head1 TABLE: C<workload_characteristic>

=cut

__PACKAGE__->table("workload_characteristic");

=head1 ACCESSORS

=head2 wc_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 wc_visit_ratio

  data_type: 'double precision'
  is_nullable: 0

=head2 wc_service_time

  data_type: 'double precision'
  is_nullable: 0

=head2 wc_delay

  data_type: 'double precision'
  is_nullable: 0

=head2 wc_think_time

  data_type: 'double precision'
  is_nullable: 0

=head2 cluster_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "wc_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "wc_visit_ratio",
  { data_type => "double precision", is_nullable => 0 },
  "wc_service_time",
  { data_type => "double precision", is_nullable => 0 },
  "wc_delay",
  { data_type => "double precision", is_nullable => 0 },
  "wc_think_time",
  { data_type => "double precision", is_nullable => 0 },
  "cluster_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</wc_id>

=back

=cut

__PACKAGE__->set_primary_key("wc_id");

=head1 RELATIONS

=head2 cluster

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Cluster>

=cut

__PACKAGE__->belongs_to(
  "cluster",
  "Kanopya::Schema::Result::Cluster",
  { cluster_id => "cluster_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xthXemdf+3xBdPBagBHcug


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
