package AdministratorDB::Schema::Result::Motherboard;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Motherboard

=cut

__PACKAGE__->table("motherboard");

=head1 ACCESSORS

=head2 motherboard_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 motherboardmodel_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 processormodel_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 kernel_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 motherboard_serial_number

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 motherboard_powersupply_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 motherboard_desc

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 active

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 motherboard_mac_address

  data_type: 'char'
  is_nullable: 0
  size: 18

=head2 motherboard_initiatorname

  data_type: 'char'
  is_nullable: 1
  size: 64

=head2 motherboard_internal_ip

  data_type: 'char'
  is_nullable: 1
  size: 15

=head2 motherboard_hostname

  data_type: 'char'
  is_nullable: 1
  size: 32

=head2 etc_device_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 motherboard_state

  data_type: 'char'
  default_value: 'down'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "motherboard_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "motherboardmodel_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "processormodel_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "kernel_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "motherboard_serial_number",
  { data_type => "char", is_nullable => 0, size => 64 },
  "motherboard_powersupply_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "motherboard_desc",
  { data_type => "char", is_nullable => 1, size => 255 },
  "active",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "motherboard_mac_address",
  { data_type => "char", is_nullable => 0, size => 18 },
  "motherboard_initiatorname",
  { data_type => "char", is_nullable => 1, size => 64 },
  "motherboard_internal_ip",
  { data_type => "char", is_nullable => 1, size => 15 },
  "motherboard_hostname",
  { data_type => "char", is_nullable => 1, size => 32 },
  "etc_device_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "motherboard_state",
  { data_type => "char", default_value => "down", is_nullable => 0, size => 32 },
);
__PACKAGE__->set_primary_key("motherboard_id");
__PACKAGE__->add_unique_constraint("motherboard_internal_ip_UNIQUE", ["motherboard_internal_ip"]);
__PACKAGE__->add_unique_constraint("motherboard_mac_address_UNIQUE", ["motherboard_mac_address"]);

=head1 RELATIONS

=head2 motherboardmodel

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Motherboardmodel>

=cut

__PACKAGE__->belongs_to(
  "motherboardmodel",
  "AdministratorDB::Schema::Result::Motherboardmodel",
  { motherboardmodel_id => "motherboardmodel_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 processormodel

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Processormodel>

=cut

__PACKAGE__->belongs_to(
  "processormodel",
  "AdministratorDB::Schema::Result::Processormodel",
  { processormodel_id => "processormodel_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 kernel

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Kernel>

=cut

__PACKAGE__->belongs_to(
  "kernel",
  "AdministratorDB::Schema::Result::Kernel",
  { kernel_id => "kernel_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 etc_device

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Lvm2Lv>

=cut

__PACKAGE__->belongs_to(
  "etc_device",
  "AdministratorDB::Schema::Result::Lvm2Lv",
  { lvm2_lv_id => "etc_device_id" },
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 motherboard_powersupply

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Powersupply>

=cut

__PACKAGE__->belongs_to(
  "motherboard_powersupply",
  "AdministratorDB::Schema::Result::Powersupply",
  { powersupply_id => "motherboard_powersupply_id" },
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 motherboard_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::MotherboardEntity>

=cut

__PACKAGE__->might_have(
  "motherboard_entity",
  "AdministratorDB::Schema::Result::MotherboardEntity",
  { "foreign.motherboard_id" => "self.motherboard_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 motherboarddetails

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Motherboarddetail>

=cut

__PACKAGE__->has_many(
  "motherboarddetails",
  "AdministratorDB::Schema::Result::Motherboarddetail",
  { "foreign.motherboard_id" => "self.motherboard_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 node

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Node>

=cut

__PACKAGE__->might_have(
  "node",
  "AdministratorDB::Schema::Result::Node",
  { "foreign.motherboard_id" => "self.motherboard_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Vik+D8QWi4RW6WYeT+tNVw


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::Result::MotherboardEntity",
    { "foreign.motherboard_id" => "self.motherboard_id" },
    { cascade_copy => 0, cascade_delete => 0 });
1;
