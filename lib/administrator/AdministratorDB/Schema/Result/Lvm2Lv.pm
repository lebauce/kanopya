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

=head2 lvm2_vg

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Lvm2Vg>

=cut

__PACKAGE__->belongs_to(
  "lvm2_vg",
  "AdministratorDB::Schema::Result::Lvm2Vg",
  { lvm2_vg_id => "lvm2_vg_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-02-16 20:32:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Z1miWC4OiEh0yplRBeE4lQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
