package AdministratorDB::Schema::Result::Iscsitarget1Lun;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Iscsitarget1Lun

=cut

__PACKAGE__->table("iscsitarget1_lun");

=head1 ACCESSORS

=head2 iscsitarget1_lun_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 iscsitarget1_target_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 iscsitarget1_lun_number

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 iscsitarget1_lun_device

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 iscsitarget1_lun_typeio

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 iscsitarget1_lun_iomode

  data_type: 'char'
  is_nullable: 0
  size: 16

=cut

__PACKAGE__->add_columns(
  "iscsitarget1_lun_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "iscsitarget1_target_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "iscsitarget1_lun_number",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "iscsitarget1_lun_device",
  { data_type => "char", is_nullable => 0, size => 64 },
  "iscsitarget1_lun_typeio",
  { data_type => "char", is_nullable => 0, size => 32 },
  "iscsitarget1_lun_iomode",
  { data_type => "char", is_nullable => 0, size => 16 },
);
__PACKAGE__->set_primary_key("iscsitarget1_lun_id");

=head1 RELATIONS

=head2 iscsitarget1_target

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Iscsitarget1Target>

=cut

__PACKAGE__->belongs_to(
  "iscsitarget1_target",
  "AdministratorDB::Schema::Result::Iscsitarget1Target",
  { iscsitarget1_target_id => "iscsitarget1_target_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-25 14:17:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ExA9fFXinUxN7JUCuI/QFQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
