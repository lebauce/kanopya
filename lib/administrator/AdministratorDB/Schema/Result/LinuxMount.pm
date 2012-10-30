package AdministratorDB::Schema::Result::LinuxMount;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::LinuxMount

=cut

__PACKAGE__->table("linux_mount");

=head1 ACCESSORS

=head2 linux_mount_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 linux_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 linux_mount_device

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 linux_mount_point

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 linux_mount_filesystem

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 linux_mount_options

  data_type: 'char'
  default_value: 'defaults'
  is_nullable: 0
  size: 128

=head2 linux_mount_dumpfreq

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 linux_mount_passnum

  data_type: 'enum'
  default_value: 0
  extra: {list => [0,1,2]}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "linux_mount_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "linux_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "linux_mount_device",
  { data_type => "char", is_nullable => 0, size => 64 },
  "linux_mount_point",
  { data_type => "char", is_nullable => 0, size => 64 },
  "linux_mount_filesystem",
  { data_type => "char", is_nullable => 0, size => 32 },
  "linux_mount_options",
  {
    data_type => "char",
    default_value => "defaults",
    is_nullable => 0,
    size => 128,
  },
  "linux_mount_dumpfreq",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "linux_mount_passnum",
  {
    data_type => "enum",
    default_value => 0,
    extra => { list => [0, 1, 2] },
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("linux_mount_id");
__PACKAGE__->add_unique_constraint(
  "linux_mount_unique1",
  ["linux_mount_id", "linux_mount_device", "linux_mount_point"],
);

=head1 RELATIONS

=head2 linux

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Linux>

=cut

__PACKAGE__->belongs_to(
  "linux",
  "AdministratorDB::Schema::Result::Linux",
  { linux_id => "linux_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-05-28 11:11:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZlyioTe00Uh5TByiAO7gqQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
