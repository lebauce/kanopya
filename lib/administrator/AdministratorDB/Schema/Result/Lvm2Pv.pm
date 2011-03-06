package AdministratorDB::Schema::Result::Lvm2Pv;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Lvm2Pv

=cut

__PACKAGE__->table("lvm2_pv");

=head1 ACCESSORS

=head2 lvm2_pv_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 lvm2_vg_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 lvm2_pv_name

  data_type: 'char'
  is_nullable: 0
  size: 64

=cut

__PACKAGE__->add_columns(
  "lvm2_pv_id",
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
  "lvm2_pv_name",
  { data_type => "char", is_nullable => 0, size => 64 },
);
__PACKAGE__->set_primary_key("lvm2_pv_id");
__PACKAGE__->add_unique_constraint("lvm2_UNIQUE", ["lvm2_pv_name"]);

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


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NPKY+9r7FXmwXk0R6xmzwA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
