package AdministratorDB::Schema::Result::Clustermetric;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Clustermetric

=cut

__PACKAGE__->table("clustermetric");

=head1 ACCESSORS

=head2 clustermetric_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 clustermetric_cluster_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 clustermetric_indicator_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 clustermetric_statistics_function_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 clustermetric_window_time

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "clustermetric_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "clustermetric_cluster_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "clustermetric_indicator_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "clustermetric_statistics_function_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "clustermetric_window_time",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
    "class_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("clustermetric_id");

=head1 RELATIONS

=head2 indicator

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Indicator>

=cut

__PACKAGE__->belongs_to(
  "indicator",
  "AdministratorDB::Schema::Result::Indicator",
  { indicator_id => "clustermetric_indicator_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 cluster

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Cluster>

=cut

__PACKAGE__->belongs_to(
  "cluster",
  "AdministratorDB::Schema::Result::Cluster",
  { cluster_id => "clustermetric_cluster_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-02-02 12:58:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cU9famXGyvu272hZDKoaSQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
