use utf8;
package Kanopya::Schema::Result::Host;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Host

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

=head1 TABLE: C<host>

=cut

__PACKAGE__->table("host");

=head1 ACCESSORS

=head2 host_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 host_manager_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 hostmodel_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 processormodel_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 kernel_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 host_serial_number

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 host_desc

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 active

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 host_initiatorname

  data_type: 'char'
  is_nullable: 1
  size: 64

=head2 host_ram

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 host_core

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 host_state

  data_type: 'char'
  default_value: 'down:0'
  is_nullable: 0
  size: 32

=head2 host_prev_state

  data_type: 'char'
  is_nullable: 1
  size: 32

=cut

__PACKAGE__->add_columns(
  "host_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "host_manager_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "hostmodel_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "processormodel_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "kernel_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "host_serial_number",
  { data_type => "char", is_nullable => 0, size => 64 },
  "host_desc",
  { data_type => "char", is_nullable => 1, size => 255 },
  "active",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "host_initiatorname",
  { data_type => "char", is_nullable => 1, size => 64 },
  "host_ram",
  { data_type => "bigint", extra => { unsigned => 1 }, is_nullable => 1 },
  "host_core",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "host_state",
  {
    data_type => "char",
    default_value => "down:0",
    is_nullable => 0,
    size => 32,
  },
  "host_prev_state",
  { data_type => "char", is_nullable => 1, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</host_id>

=back

=cut

__PACKAGE__->set_primary_key("host_id");

=head1 RELATIONS

=head2 harddisks

Type: has_many

Related object: L<Kanopya::Schema::Result::Harddisk>

=cut

__PACKAGE__->has_many(
  "harddisks",
  "Kanopya::Schema::Result::Harddisk",
  { "foreign.host_id" => "self.host_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 host

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "host",
  "Kanopya::Schema::Result::Entity",
  { entity_id => "host_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 host_manager

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "host_manager",
  "Kanopya::Schema::Result::Component",
  { component_id => "host_manager_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 hostmodel

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Hostmodel>

=cut

__PACKAGE__->belongs_to(
  "hostmodel",
  "Kanopya::Schema::Result::Hostmodel",
  { hostmodel_id => "hostmodel_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 hypervisor

Type: might_have

Related object: L<Kanopya::Schema::Result::Hypervisor>

=cut

__PACKAGE__->might_have(
  "hypervisor",
  "Kanopya::Schema::Result::Hypervisor",
  { "foreign.hypervisor_id" => "self.host_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ifaces

Type: has_many

Related object: L<Kanopya::Schema::Result::Iface>

=cut

__PACKAGE__->has_many(
  "ifaces",
  "Kanopya::Schema::Result::Iface",
  { "foreign.host_id" => "self.host_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ipmi_credentials

Type: has_many

Related object: L<Kanopya::Schema::Result::IpmiCredentials>

=cut

__PACKAGE__->has_many(
  "ipmi_credentials",
  "Kanopya::Schema::Result::IpmiCredentials",
  { "foreign.host_id" => "self.host_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 kernel

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Kernel>

=cut

__PACKAGE__->belongs_to(
  "kernel",
  "Kanopya::Schema::Result::Kernel",
  { kernel_id => "kernel_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 node

Type: might_have

Related object: L<Kanopya::Schema::Result::Node>

=cut

__PACKAGE__->might_have(
  "node",
  "Kanopya::Schema::Result::Node",
  { "foreign.host_id" => "self.host_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 processormodel

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Processormodel>

=cut

__PACKAGE__->belongs_to(
  "processormodel",
  "Kanopya::Schema::Result::Processormodel",
  { processormodel_id => "processormodel_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 virtual_machine

Type: might_have

Related object: L<Kanopya::Schema::Result::VirtualMachine>

=cut

__PACKAGE__->might_have(
  "virtual_machine",
  "Kanopya::Schema::Result::VirtualMachine",
  { "foreign.virtual_machine_id" => "self.host_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-12-17 12:00:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9VnbwtjJl4zalAJmGugQwg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
