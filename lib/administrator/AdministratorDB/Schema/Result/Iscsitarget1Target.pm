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

=head2 component_instance_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 iscsitarget1_target_name

  data_type: 'char'
  is_nullable: 0
  size: 128

=head2 mountpoint

  data_type: 'char'
  is_nullable: 1
  size: 64

=head2 mount_option

  data_type: 'char'
  is_nullable: 1
  size: 32

=cut

__PACKAGE__->add_columns(
  "iscsitarget1_target_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "component_instance_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "iscsitarget1_target_name",
  { data_type => "char", is_nullable => 0, size => 128 },
  "mountpoint",
  { data_type => "char", is_nullable => 1, size => 64 },
  "mount_option",
  { data_type => "char", is_nullable => 1, size => 32 },
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

=head2 component_instance

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ComponentInstance>

=cut

__PACKAGE__->belongs_to(
  "component_instance",
  "AdministratorDB::Schema::Result::ComponentInstance",
  { component_instance_id => "component_instance_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+HJCMJFKd91oElDIMTRMyQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
