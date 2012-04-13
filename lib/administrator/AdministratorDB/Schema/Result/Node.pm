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

=head2 inside_id

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

=cut

__PACKAGE__->add_columns(
  "node_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "inside_id",
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
);
__PACKAGE__->set_primary_key("node_id");
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
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 inside

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Inside>

=cut

__PACKAGE__->belongs_to(
  "inside",
  "AdministratorDB::Schema::Result::Inside",
  { inside_id => "inside_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 systemimage

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Systemimage>

=cut

__PACKAGE__->belongs_to(
  "systemimage",
  "AdministratorDB::Schema::Result::Systemimage",
  { systemimage_id => "systemimage_id" },
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-03-21 21:53:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bYRnhBPKC/6DAUTGm45kcA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
