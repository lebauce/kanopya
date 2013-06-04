use utf8;
package AdministratorDB::Schema::Result::Node;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Node

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

=head1 TABLE: C<node>

=cut

__PACKAGE__->table("node");

=head1 ACCESSORS

=head2 node_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 service_provider_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 host_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 node_number

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 node_hostname

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 systemimage_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 node_state

  data_type: 'char'
  is_nullable: 1
  size: 32

=head2 node_prev_state

  data_type: 'char'
  is_nullable: 1
  size: 32

=head2 monitoring_state

  data_type: 'char'
  default_value: 'enabled'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "node_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "service_provider_id",
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
    is_nullable => 1,
  },
  "node_number",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "node_hostname",
  { data_type => "char", is_nullable => 0, size => 255 },
  "systemimage_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "node_state",
  { data_type => "char", is_nullable => 1, size => 32 },
  "node_prev_state",
  { data_type => "char", is_nullable => 1, size => 32 },
  "monitoring_state",
  {
    data_type => "char",
    default_value => "enabled",
    is_nullable => 0,
    size => 32,
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

=head2 C<node_hostname>

=over 4

=item * L</node_hostname>

=item * L</service_provider_id>

=back

=cut

__PACKAGE__->add_unique_constraint("node_hostname", ["node_hostname", "service_provider_id"]);

=head1 RELATIONS

=head2 component_nodes

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ComponentNode>

=cut

__PACKAGE__->has_many(
  "component_nodes",
  "AdministratorDB::Schema::Result::ComponentNode",
  { "foreign.node_id" => "self.node_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 data_models

Type: has_many

Related object: L<AdministratorDB::Schema::Result::DataModel>

=cut

__PACKAGE__->has_many(
  "data_models",
  "AdministratorDB::Schema::Result::DataModel",
  { "foreign.node_id" => "self.node_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 host

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Host>

=cut

__PACKAGE__->belongs_to(
  "host",
  "AdministratorDB::Schema::Result::Host",
  { host_id => "host_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 service_provider

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "service_provider",
  "AdministratorDB::Schema::Result::ServiceProvider",
  { service_provider_id => "service_provider_id" },
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

=head2 verified_noderules

Type: has_many

Related object: L<AdministratorDB::Schema::Result::VerifiedNoderule>

=cut

__PACKAGE__->has_many(
  "verified_noderules",
  "AdministratorDB::Schema::Result::VerifiedNoderule",
  { "foreign.verified_noderule_node_id" => "self.node_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workflow_noderules

Type: has_many

Related object: L<AdministratorDB::Schema::Result::WorkflowNoderule>

=cut

__PACKAGE__->has_many(
  "workflow_noderules",
  "AdministratorDB::Schema::Result::WorkflowNoderule",
  { "foreign.node_id" => "self.node_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2013-02-28 14:52:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:m497yb3OpA0l2GyZfvEXoQ

__PACKAGE__->many_to_many("components", "component_nodes", "component");

1;
