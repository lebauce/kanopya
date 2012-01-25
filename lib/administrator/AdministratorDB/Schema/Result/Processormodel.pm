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
  is_foreign_key: 1
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

=head2 processormodel_virtsupport

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "processormodel_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
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

=head2 hosts

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Host>

=cut

__PACKAGE__->has_many(
  "hosts",
  "AdministratorDB::Schema::Result::Host",
  { "foreign.processormodel_id" => "self.processormodel_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 hostmodels

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Hostmodel>

=cut

__PACKAGE__->has_many(
  "hostmodels",
  "AdministratorDB::Schema::Result::Hostmodel",
  { "foreign.processormodel_id" => "self.processormodel_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 processormodel

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "processormodel",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "processormodel_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-25 14:19:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ig5TncdiGCCgqUquQQZtRg


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::Result::ProcessormodelEntity",
    { "foreign.processormodel_id" => "self.processormodel_id" },
    { cascade_copy => 0, cascade_delete => 0 });
1;
