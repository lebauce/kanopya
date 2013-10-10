use utf8;
package AdministratorDB::Schema::Result::ComponentNode;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::ComponentNode

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

=head1 TABLE: C<component_node>

=cut

__PACKAGE__->table("component_node");

=head1 ACCESSORS

=head2 component_node_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 component_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 node_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 master_node

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "component_node_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "component_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "node_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "master_node",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</component_node_id>

=back

=cut

__PACKAGE__->set_primary_key("component_node_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<component_id>

=over 4

=item * L</component_id>

=item * L</node_id>

=back

=cut

__PACKAGE__->add_unique_constraint("component_id", ["component_id", "node_id"]);

=head1 RELATIONS

=head2 component

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "component",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "component_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 node

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Node>

=cut

__PACKAGE__->belongs_to(
  "node",
  "AdministratorDB::Schema::Result::Node",
  { node_id => "node_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2013-02-28 14:52:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:si4PM8y0Dz8sKa97nDrVBQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
