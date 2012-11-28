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
  is_foreign_key: 1
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
    is_foreign_key => 1,
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
__PACKAGE__->add_unique_constraint("hostmodel_name", ["hostmodel_name"]);

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

=head2 hostmodel

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "hostmodel",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "hostmodel_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-02-02 10:20:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rwZYyt4HpfcALa8l9qxh0A


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
    { "foreign.entity_id" => "self.hostmodel_id" },
    { cascade_copy => 0, cascade_delete => 0 });
1;
