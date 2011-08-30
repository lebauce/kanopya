package AdministratorDB::Schema::Result::Processormodel;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Processormodel

=cut

__PACKAGE__->table("processormodel");

=head1 ACCESSORS

=head2 processormodel_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 processormodel_brand

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 processormodel_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 processormodel_core_num

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 processormodel_clock_speed

  data_type: 'float'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 processormodel_l2_cache

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 processormodel_max_tdp

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 processormodel_64bits

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "processormodel_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "processormodel_brand",
  { data_type => "char", is_nullable => 0, size => 64 },
  "processormodel_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "processormodel_core_num",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "processormodel_clock_speed",
  { data_type => "float", extra => { unsigned => 1 }, is_nullable => 0 },
  "processormodel_l2_cache",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "processormodel_max_tdp",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "processormodel_64bits",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "processormodel_virtsupport",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("processormodel_id");
__PACKAGE__->add_unique_constraint("processormodel_name_UNIQUE", ["processormodel_name"]);

=head1 RELATIONS

=head2 motherboards

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Motherboard>

=cut

__PACKAGE__->has_many(
  "motherboards",
  "AdministratorDB::Schema::Result::Motherboard",
  { "foreign.processormodel_id" => "self.processormodel_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 motherboardmodels

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Motherboardmodel>

=cut

__PACKAGE__->has_many(
  "motherboardmodels",
  "AdministratorDB::Schema::Result::Motherboardmodel",
  { "foreign.processormodel_id" => "self.processormodel_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 processormodel_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::ProcessormodelEntity>

=cut

__PACKAGE__->might_have(
  "processormodel_entity",
  "AdministratorDB::Schema::Result::ProcessormodelEntity",
  { "foreign.processormodel_id" => "self.processormodel_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kx97oUcKGDSBYv5jtuokZg


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::Result::ProcessormodelEntity",
    { "foreign.processormodel_id" => "self.processormodel_id" },
    { cascade_copy => 0, cascade_delete => 0 });
1;
