package AdministratorDB::Schema::Result::Hostmodel;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Hostmodel

=cut

__PACKAGE__->table("hostmodel");

=head1 ACCESSORS

=head2 hostmodel_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 hostmodel_brand

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 hostmodel_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 hostmodel_chipset

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 hostmodel_processor_num

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 hostmodel_consumption

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 hostmodel_iface_num

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 hostmodel_ram_slot_num

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 hostmodel_ram_max

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
  "hostmodel_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "hostmodel_brand",
  { data_type => "char", is_nullable => 0, size => 64 },
  "hostmodel_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "hostmodel_chipset",
  { data_type => "char", is_nullable => 0, size => 64 },
  "hostmodel_processor_num",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "hostmodel_consumption",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "hostmodel_iface_num",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "hostmodel_ram_slot_num",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "hostmodel_ram_max",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "processormodel_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("hostmodel_id");
__PACKAGE__->add_unique_constraint("hostmodel_name_UNIQUE", ["hostmodel_name"]);

=head1 RELATIONS

=head2 hosts

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Host>

=cut

__PACKAGE__->has_many(
  "hosts",
  "AdministratorDB::Schema::Result::Host",
  { "foreign.hostmodel_id" => "self.hostmodel_id" },
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

=head2 hostmodel_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::HostmodelEntity>

=cut

__PACKAGE__->might_have(
  "hostmodel_entity",
  "AdministratorDB::Schema::Result::HostmodelEntity",
  { "foreign.hostmodel_id" => "self.hostmodel_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:V7HpuY2CVhjjTANxaAIDAw


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::Result::HostmodelEntity",
    { "foreign.hostmodel_id" => "self.hostmodel_id" },
    { cascade_copy => 0, cascade_delete => 0 });
1;
