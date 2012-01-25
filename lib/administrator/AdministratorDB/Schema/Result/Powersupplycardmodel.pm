package AdministratorDB::Schema::Result::Powersupplycardmodel;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Powersupplycardmodel

=cut

__PACKAGE__->table("powersupplycardmodel");

=head1 ACCESSORS

=head2 powersupplycardmodel_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 powersupplycardmodel_brand

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 powersupplycardmodel_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 powersupplycardmodel_slotscount

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "powersupplycardmodel_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "powersupplycardmodel_brand",
  { data_type => "char", is_nullable => 0, size => 64 },
  "powersupplycardmodel_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "powersupplycardmodel_slotscount",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("powersupplycardmodel_id");
__PACKAGE__->add_unique_constraint(
  "powersupplycardmodel_name_UNIQUE",
  ["powersupplycardmodel_name"],
);

=head1 RELATIONS

=head2 powersupplycards

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Powersupplycard>

=cut

__PACKAGE__->has_many(
  "powersupplycards",
  "AdministratorDB::Schema::Result::Powersupplycard",
  {
    "foreign.powersupplycardmodel_id" => "self.powersupplycardmodel_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 powersupplycardmodel

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "powersupplycardmodel",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "powersupplycardmodel_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-25 14:19:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eTfUzt6QXtQE9OUXBM2CMg


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::Result::PowersupplycardmodelEntity",
    { "foreign.powersupplycardmodel_id" => "self.powersupplycardmodel_id" },
    { cascade_copy => 0, cascade_delete => 0 });
1;
