package AdministratorDB::Schema::Result::Motherboardmodel;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Motherboardmodel

=cut

__PACKAGE__->table("motherboardmodel");

=head1 ACCESSORS

=head2 motherboardmodel_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 motherboardmodel_brand

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 motherboardmodel_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 motherboardmodel_chipset

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 motherboardmodel_processor_num

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 motherboardmodel_consumption

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 motherboardmodel_iface_num

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 motherboardmodel_ram_slot_num

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 motherboardmodel_ram_max

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 processormodel_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "motherboardmodel_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "motherboardmodel_brand",
  { data_type => "char", is_nullable => 0, size => 64 },
  "motherboardmodel_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "motherboardmodel_chipset",
  { data_type => "char", is_nullable => 0, size => 64 },
  "motherboardmodel_processor_num",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "motherboardmodel_consumption",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "motherboardmodel_iface_num",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "motherboardmodel_ram_slot_num",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "motherboardmodel_ram_max",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "processormodel_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("motherboardmodel_id");
__PACKAGE__->add_unique_constraint("motherboardmodel_name_UNIQUE", ["motherboardmodel_name"]);

=head1 RELATIONS

=head2 motherboards

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Motherboard>

=cut

__PACKAGE__->has_many(
  "motherboards",
  "AdministratorDB::Schema::Result::Motherboard",
  { "foreign.motherboardmodel_id" => "self.motherboardmodel_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 processormodel

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Processormodel>

=cut

__PACKAGE__->belongs_to(
  "processormodel",
  "AdministratorDB::Schema::Result::Processormodel",
  { processormodel_id => "processormodel_id" },
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 motherboardmodel_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::MotherboardmodelEntity>

=cut

__PACKAGE__->might_have(
  "motherboardmodel_entity",
  "AdministratorDB::Schema::Result::MotherboardmodelEntity",
  { "foreign.motherboardmodel_id" => "self.motherboardmodel_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:V7HpuY2CVhjjTANxaAIDAw


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::Result::MotherboardmodelEntity",
    { "foreign.motherboardmodel_id" => "self.motherboardmodel_id" },
    { cascade_copy => 0, cascade_delete => 0 });
1;
