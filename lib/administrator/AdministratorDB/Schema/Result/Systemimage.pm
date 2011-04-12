package AdministratorDB::Schema::Result::Systemimage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Systemimage

=cut

__PACKAGE__->table("systemimage");

=head1 ACCESSORS

=head2 systemimage_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 systemimage_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 systemimage_desc

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 systemimage_dedicated

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 distribution_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 etc_device_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 root_device_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 active

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "systemimage_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "systemimage_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "systemimage_desc",
  { data_type => "char", is_nullable => 1, size => 255 },
  "systemimage_dedicated",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "distribution_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "etc_device_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "root_device_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "active",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("systemimage_id");
__PACKAGE__->add_unique_constraint("systemimage_name_UNIQUE", ["systemimage_name"]);

=head1 RELATIONS

=head2 components_installed

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ComponentInstalled>

=cut

__PACKAGE__->has_many(
  "components_installed",
  "AdministratorDB::Schema::Result::ComponentInstalled",
  { "foreign.systemimage_id" => "self.systemimage_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 distribution

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Distribution>

=cut

__PACKAGE__->belongs_to(
  "distribution",
  "AdministratorDB::Schema::Result::Distribution",
  { distribution_id => "distribution_id" },
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

=head2 root_device

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Lvm2Lv>

=cut

__PACKAGE__->belongs_to(
  "root_device",
  "AdministratorDB::Schema::Result::Lvm2Lv",
  { lvm2_lv_id => "root_device_id" },
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 systemimage_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::SystemimageEntity>

=cut

__PACKAGE__->might_have(
  "systemimage_entity",
  "AdministratorDB::Schema::Result::SystemimageEntity",
  { "foreign.systemimage_id" => "self.systemimage_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-04-12 15:20:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GugKYaadEHYSYqSFdtET2Q


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::Result::SystemimageEntity",
    { "foreign.systemimage_id" => "self.systemimage_id" },
    { cascade_copy => 0, cascade_delete => 0 });
1;
