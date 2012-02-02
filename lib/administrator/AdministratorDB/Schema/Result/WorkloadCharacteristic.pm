package AdministratorDB::Schema::Result::WorkloadCharacteristic;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::WorkloadCharacteristic

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
__PACKAGE__->set_primary_key("wc_id");

=head1 RELATIONS

=head2 cluster

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Cluster>

=cut

__PACKAGE__->belongs_to(
  "cluster",
  "AdministratorDB::Schema::Result::Cluster",
  { cluster_id => "cluster_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-25 14:17:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3YbHJaznSb28QZ9i776Adw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
