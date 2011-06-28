package AdministratorDB::Schema::Result::Node;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Node

=cut

__PACKAGE__->table("node");

=head1 ACCESSORS

=head2 node_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 cluster_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 motherboard_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 master_node

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 node_state

  data_type: 'char'
  is_nullable: 1
  size: 20

=cut

=head2 node_prev_state

  data_type: 'char'
  is_nullable: 1
  size: 20

=cut


__PACKAGE__->add_columns(
  "node_id",
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
  "motherboard_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "master_node",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "node_state",
  { data_type => "char", is_nullable => 1, size => 20 },
  "node_prev_state",
  { data_type => "char", is_nullable => 1, size => 20 },
);
__PACKAGE__->set_primary_key("node_id");
__PACKAGE__->add_unique_constraint("cluster_id", ["cluster_id", "motherboard_id"]);
__PACKAGE__->add_unique_constraint("fk_node_2", ["motherboard_id"]);

=head1 RELATIONS

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

=head2 motherboard

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Motherboard>

=cut

__PACKAGE__->belongs_to(
  "motherboard",
  "AdministratorDB::Schema::Result::Motherboard",
  { motherboard_id => "motherboard_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KOhhfx9RpiJ/GwPiJUcA5Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
