use utf8;
package AdministratorDB::Schema::Result::Node;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Node

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<node>

=cut

__PACKAGE__->table("node");

=head1 ACCESSORS

=head2 node_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 host_id

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
  size: 32

=head2 node_prev_state

  data_type: 'char'
  is_nullable: 1
  size: 32

=head2 node_number

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 systemimage_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 inside_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "node_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "host_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "master_node",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "node_state",
  { data_type => "char", is_nullable => 1, size => 32 },
  "node_prev_state",
  { data_type => "char", is_nullable => 1, size => 32 },
  "node_number",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "systemimage_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "inside_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</node_id>

=back

=cut

__PACKAGE__->set_primary_key("node_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<host_id>

=over 4

=item * L</host_id>

=back

=cut

__PACKAGE__->add_unique_constraint("host_id", ["host_id"]);

=head1 RELATIONS

=head2 host

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Host>

=cut

__PACKAGE__->belongs_to(
  "host",
  "AdministratorDB::Schema::Result::Host",
  { host_id => "host_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 inside

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Inside>

=cut

__PACKAGE__->belongs_to(
  "inside",
  "AdministratorDB::Schema::Result::Inside",
  { inside_id => "inside_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 node

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Externalnode>

=cut

__PACKAGE__->belongs_to(
  "node",
  "AdministratorDB::Schema::Result::Externalnode",
  { externalnode_id => "node_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 systemimage

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Systemimage>

=cut

__PACKAGE__->belongs_to(
  "systemimage",
  "AdministratorDB::Schema::Result::Systemimage",
  { systemimage_id => "systemimage_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-06-20 15:42:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CGc3DTiiUd11o1xwOaA3vw


# You can replace this text with custom code or comments, and it will be preserved on regeneration

__PACKAGE__->belongs_to(
      "parent",
      "AdministratorDB::Schema::Result::Externalnode",
       { "foreign.externalnode_id" => "self.node_id" },
       { cascade_copy => 0, cascade_delete => 1 }
);


1;
