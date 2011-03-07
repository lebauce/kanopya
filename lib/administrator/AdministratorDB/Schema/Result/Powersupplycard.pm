package AdministratorDB::Schema::Result::Powersupplycard;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Powersupplycard

=cut

__PACKAGE__->table("powersupplycard");

=head1 ACCESSORS

=head2 powersupplycard_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 powersupplycard_name

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 powersupplycard_ip

  data_type: 'char'
  is_nullable: 1
  size: 15

=head2 powersupplycardmodel_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 powersupplycard_mac_address

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 active

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "powersupplycard_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "powersupplycard_name",
  { data_type => "char", is_nullable => 0, size => 64 },
  "powersupplycard_ip",
  { data_type => "char", is_nullable => 1, size => 15 },
  "powersupplycardmodel_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "powersupplycard_mac_address",
  { data_type => "char", is_nullable => 0, size => 32 },
  "active",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("powersupplycard_id");

=head1 RELATIONS

=head2 powersupplies

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Powersupply>

=cut

__PACKAGE__->has_many(
  "powersupplies",
  "AdministratorDB::Schema::Result::Powersupply",
  { "foreign.powersupplycard_id" => "self.powersupplycard_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 powersupplycardmodel

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Powersupplycardmodel>

=cut

__PACKAGE__->belongs_to(
  "powersupplycardmodel",
  "AdministratorDB::Schema::Result::Powersupplycardmodel",
  { powersupplycardmodel_id => "powersupplycardmodel_id" },
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 powersupplycard_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::PowersupplycardEntity>

=cut

__PACKAGE__->might_have(
  "powersupplycard_entity",
  "AdministratorDB::Schema::Result::PowersupplycardEntity",
  { "foreign.powersupplycard_id" => "self.powersupplycard_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sOxbSkrCywWA5PU9E9ohSw


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::Result::PowersupplycardEntity",
    { "foreign.powersupplycard_id" => "self.powersupplycard_id" },
    { cascade_copy => 0, cascade_delete => 0 });
1;
