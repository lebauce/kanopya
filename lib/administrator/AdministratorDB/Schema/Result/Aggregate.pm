package AdministratorDB::Schema::Result::Aggregate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Aggregate

=cut

__PACKAGE__->table("aggregate");

=head1 ACCESSORS

=head2 aggregate_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 cluster_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 indicator_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 statistics_function_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 window_time

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "aggregate_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "cluster_id",
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
  "statistics_function_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "window_time",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("aggregate_id");

=head1 RELATIONS

=head2 indicator

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Indicator>

=cut

__PACKAGE__->belongs_to(
  "indicator",
  "AdministratorDB::Schema::Result::Indicator",
  { indicator_id => "indicator_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 cluster

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Cluster>

=cut

__PACKAGE__->belongs_to(
  "cluster",
  "AdministratorDB::Schema::Result::Cluster",
  { cluster_id => "cluster_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-02-02 12:58:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cU9famXGyvu272hZDKoaSQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
