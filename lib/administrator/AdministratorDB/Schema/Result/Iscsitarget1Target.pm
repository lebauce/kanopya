package AdministratorDB::Schema::Result::Iscsitarget1Target;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Iscsitarget1Target

=cut

__PACKAGE__->table("iscsitarget1_target");

=head1 ACCESSORS

=head2 iscsitarget1_target_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 iscsitarget1_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 iscsitarget1_target_name

  data_type: 'char'
  is_nullable: 0
  size: 128

=cut

__PACKAGE__->add_columns(
  "iscsitarget1_target_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "iscsitarget1_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "iscsitarget1_target_name",
  { data_type => "char", is_nullable => 0, size => 128 },
);
__PACKAGE__->set_primary_key("iscsitarget1_target_id");
__PACKAGE__->add_unique_constraint("iscsitarget1_UNIQUE", ["iscsitarget1_target_name"]);

=head1 RELATIONS

=head2 iscsitarget1_luns

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Iscsitarget1Lun>

=cut

__PACKAGE__->has_many(
  "iscsitarget1_luns",
  "AdministratorDB::Schema::Result::Iscsitarget1Lun",
  {
    "foreign.iscsitarget1_target_id" => "self.iscsitarget1_target_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 iscsitarget1

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Iscsitarget1>

=cut

__PACKAGE__->belongs_to(
  "iscsitarget1",
  "AdministratorDB::Schema::Result::Iscsitarget1",
  { iscsitarget1_id => "iscsitarget1_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-26 16:29:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rwcCd7TTcBOA4LkmPuWwjg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
