package AdministratorDB::Schema::Result::Lvm2Lv;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Lvm2Lv

=cut

__PACKAGE__->table("lvm2_lv");

=head1 ACCESSORS

=head2 lvm2_lv_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 lvm2_vg_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 lvm2_lv_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 lvm2_lv_size

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 lvm2_lv_freespace

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 lvm2_lv_filesystem

  data_type: 'char'
  is_nullable: 0
  size: 10

=cut

__PACKAGE__->add_columns(
  "lvm2_lv_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "lvm2_vg_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "lvm2_lv_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "lvm2_lv_size",
  { data_type => "bigint", extra => { unsigned => 1 }, is_nullable => 0 },
  "lvm2_lv_freespace",
  { data_type => "bigint", extra => { unsigned => 1 }, is_nullable => 0 },
  "lvm2_lv_filesystem",
  { data_type => "char", is_nullable => 0, size => 10 },
);
__PACKAGE__->set_primary_key("lvm2_lv_id");

=head1 RELATIONS

=head2 distribution_etc_devices

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Distribution>

=cut

__PACKAGE__->has_many(
  "distribution_etc_devices",
  "AdministratorDB::Schema::Result::Distribution",
  { "foreign.etc_device_id" => "self.lvm2_lv_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 distribution_root_devices

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Distribution>

=cut

__PACKAGE__->has_many(
  "distribution_root_devices",
  "AdministratorDB::Schema::Result::Distribution",
  { "foreign.root_device_id" => "self.lvm2_lv_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 hosts

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Host>

=cut

__PACKAGE__->has_many(
  "hosts",
  "AdministratorDB::Schema::Result::Host",
  { "foreign.etc_device_id" => "self.lvm2_lv_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 lvm2_vg

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Lvm2Vg>

=cut

__PACKAGE__->belongs_to(
  "lvm2_vg",
  "AdministratorDB::Schema::Result::Lvm2Vg",
  { lvm2_vg_id => "lvm2_vg_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 systemimage_etc_devices

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Systemimage>

=cut

__PACKAGE__->has_many(
  "systemimage_etc_devices",
  "AdministratorDB::Schema::Result::Systemimage",
  { "foreign.etc_device_id" => "self.lvm2_lv_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 systemimage_root_devices

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Systemimage>

=cut

__PACKAGE__->has_many(
  "systemimage_root_devices",
  "AdministratorDB::Schema::Result::Systemimage",
  { "foreign.root_device_id" => "self.lvm2_lv_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-25 14:17:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NshNk8gfad41+xksjq4KpA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
