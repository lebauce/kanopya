package AdministratorDB::Schema::Result::Lvm2Vg;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Lvm2Vg

=cut

__PACKAGE__->table("lvm2_vg");

=head1 ACCESSORS

=head2 lvm2_vg_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 lvm2_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 lvm2_vg_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 lvm2_vg_freespace

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 lvm2_vg_size

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "lvm2_vg_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "lvm2_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "lvm2_vg_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "lvm2_vg_freespace",
  { data_type => "bigint", extra => { unsigned => 1 }, is_nullable => 0 },
  "lvm2_vg_size",
  { data_type => "bigint", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("lvm2_vg_id");

=head1 RELATIONS

=head2 lvm2_lvs

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Lvm2Lv>

=cut

__PACKAGE__->has_many(
  "lvm2_lvs",
  "AdministratorDB::Schema::Result::Lvm2Lv",
  { "foreign.lvm2_vg_id" => "self.lvm2_vg_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 lvm2_pvs

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Lvm2Pv>

=cut

__PACKAGE__->has_many(
  "lvm2_pvs",
  "AdministratorDB::Schema::Result::Lvm2Pv",
  { "foreign.lvm2_vg_id" => "self.lvm2_vg_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 lvm2

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Lvm2>

=cut

__PACKAGE__->belongs_to(
  "lvm2",
  "AdministratorDB::Schema::Result::Lvm2",
  { lvm2_id => "lvm2_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-26 16:29:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XkDS+AcLrmKCu+ypUdXyOQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
