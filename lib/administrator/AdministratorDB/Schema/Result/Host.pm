package AdministratorDB::Schema::Result::Host;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Host

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
  is_nullable: 0

=head2 host_serial_number

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 host_powersupply_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

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

=head2 host_hostname

  data_type: 'char'
  is_nullable: 1
  size: 32

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
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
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
    is_nullable => 0,
  },
  "host_serial_number",
  { data_type => "char", is_nullable => 0, size => 64 },
  "host_powersupply_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
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
  "host_hostname",
  { data_type => "char", is_nullable => 1, size => 32 },
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
__PACKAGE__->set_primary_key("host_id");

=head1 RELATIONS

=head2 harddisks

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Harddisk>

=cut

__PACKAGE__->has_many(
  "harddisks",
  "AdministratorDB::Schema::Result::Harddisk",
  { "foreign.host_id" => "self.host_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 host

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "host",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "host_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 hostmodel

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Hostmodel>

=cut

__PACKAGE__->belongs_to(
  "hostmodel",
  "AdministratorDB::Schema::Result::Hostmodel",
  { hostmodel_id => "hostmodel_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 processormodel

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Processormodel>

=cut

__PACKAGE__->belongs_to(
  "processormodel",
  "AdministratorDB::Schema::Result::Processormodel",
  { processormodel_id => "processormodel_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 kernel

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Kernel>

=cut

__PACKAGE__->belongs_to(
  "kernel",
  "AdministratorDB::Schema::Result::Kernel",
  { kernel_id => "kernel_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 host_powersupply

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Powersupply>

=cut

__PACKAGE__->belongs_to(
  "host_powersupply",
  "AdministratorDB::Schema::Result::Powersupply",
  { powersupply_id => "host_powersupply_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 ifaces

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Iface>

=cut

__PACKAGE__->has_many(
  "ifaces",
  "AdministratorDB::Schema::Result::Iface",
  { "foreign.host_id" => "self.host_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 node

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Node>

=cut

__PACKAGE__->might_have(
  "node",
  "AdministratorDB::Schema::Result::Node",
  { "foreign.host_id" => "self.host_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 opennebula3_hypervisors

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Opennebula3Hypervisor>

=cut

__PACKAGE__->has_many(
  "opennebula3_hypervisors",
  "AdministratorDB::Schema::Result::Opennebula3Hypervisor",
  { "foreign.hypervisor_host_id" => "self.host_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 opennebula3_vms

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Opennebula3Vm>

=cut

__PACKAGE__->has_many(
  "opennebula3_vms",
  "AdministratorDB::Schema::Result::Opennebula3Vm",
  { "foreign.vm_host_id" => "self.host_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-04-13 14:46:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qgjMtnrMTrveW8/u39G+mA
__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
  { "foreign.entity_id" => "self.host_id" },
  { cascade_copy => 0, cascade_delete => 1 }
);

1;
