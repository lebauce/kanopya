package AdministratorDB::Schema::Result::Graph;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Graph

=cut

__PACKAGE__->table("graph");

=head1 ACCESSORS

=head2 indicatorset_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 cluster_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 graph_type

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 graph_percent

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 graph_sum

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 graph_indicators

  data_type: 'char'
  is_nullable: 1
  size: 128

=cut

__PACKAGE__->add_columns(
  "indicatorset_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "cluster_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "graph_type",
  { data_type => "char", is_nullable => 0, size => 32 },
  "graph_percent",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "graph_sum",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "graph_indicators",
  { data_type => "char", is_nullable => 1, size => 128 },
);
__PACKAGE__->set_primary_key("indicatorset_id", "cluster_id");

=head1 RELATIONS

=head2 indicatorset

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Indicatorset>

=cut

__PACKAGE__->belongs_to(
  "indicatorset",
  "AdministratorDB::Schema::Result::Indicatorset",
  { indicatorset_id => "indicatorset_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 cluster

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Cluster>

=cut

__PACKAGE__->belongs_to(
  "cluster",
  "AdministratorDB::Schema::Result::Cluster",
  { cluster_id => "cluster_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:InUo01Owc+bhcv3xhB598A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
