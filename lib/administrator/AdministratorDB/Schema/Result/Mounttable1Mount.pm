package AdministratorDB::Schema::Result::Mounttable1Mount;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Mounttable1Mount

=cut

__PACKAGE__->table("mounttable1_mount");

=head1 ACCESSORS

=head2 mounttable1_mount_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 mounttable1_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 mounttable1_mount_device

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 mounttable1_mount_point

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 mounttable1_mount_filesystem

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 mounttable1_mount_options

  data_type: 'char'
  default_value: 'defaults'
  is_nullable: 0
  size: 128

=head2 mounttable1_mount_dumpfreq

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 mounttable1_mount_passnum

  data_type: 'enum'
  default_value: 0
  extra: {list => [0,1,2]}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "mounttable1_mount_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "mounttable1_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "mounttable1_mount_device",
  { data_type => "char", is_nullable => 0, size => 64 },
  "mounttable1_mount_point",
  { data_type => "char", is_nullable => 0, size => 64 },
  "mounttable1_mount_filesystem",
  { data_type => "char", is_nullable => 0, size => 32 },
  "mounttable1_mount_options",
  {
    data_type => "char",
    default_value => "defaults",
    is_nullable => 0,
    size => 128,
  },
  "mounttable1_mount_dumpfreq",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "mounttable1_mount_passnum",
  {
    data_type => "enum",
    default_value => 0,
    extra => { list => [0, 1, 2] },
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("mounttable1_mount_id");
__PACKAGE__->add_unique_constraint(
  "mounttable1_mount_unique1",
  [
    "mounttable1_mount_id",
    "mounttable1_mount_device",
    "mounttable1_mount_point",
  ],
);

=head1 RELATIONS

=head2 mounttable1

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Mounttable1>

=cut

__PACKAGE__->belongs_to(
  "mounttable1",
  "AdministratorDB::Schema::Result::Mounttable1",
  { mounttable1_id => "mounttable1_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-26 17:01:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DEyJnBG1yZkPtU2/H4Mn6Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
