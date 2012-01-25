package AdministratorDB::Schema::Result::Mounttable1;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Mounttable1

=cut

__PACKAGE__->table("mounttable1");

=head1 ACCESSORS

=head2 mounttable1_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 component_instance_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 mounttable1_device

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 mounttable1_mountpoint

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 mounttable1_filesystem

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 mounttable1_options

  data_type: 'char'
  default_value: 'defaults'
  is_nullable: 0
  size: 128

=head2 mounttable1_dumpfreq

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 mounttable1_passnum

  data_type: 'enum'
  default_value: 0
  extra: {list => [0,1,2]}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "mounttable1_id",
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
  "mounttable1_device",
  { data_type => "char", is_nullable => 0, size => 64 },
  "mounttable1_mountpoint",
  { data_type => "char", is_nullable => 0, size => 64 },
  "mounttable1_filesystem",
  { data_type => "char", is_nullable => 0, size => 32 },
  "mounttable1_options",
  {
    data_type => "char",
    default_value => "defaults",
    is_nullable => 0,
    size => 128,
  },
  "mounttable1_dumpfreq",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "mounttable1_passnum",
  {
    data_type => "enum",
    default_value => 0,
    extra => { list => [0, 1, 2] },
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("mounttable1_id");
__PACKAGE__->add_unique_constraint(
  "mounttable1_unique1",
  [
    "component_instance_id",
    "mounttable1_device",
    "mounttable1_mountpoint",
  ],
);

=head1 RELATIONS

=head2 component_instance

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ComponentInstance>

=cut

__PACKAGE__->belongs_to(
  "component_instance",
  "AdministratorDB::Schema::Result::ComponentInstance",
  { component_instance_id => "component_instance_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-25 14:17:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iOH4qjV6mnL8FCZ/wSFpqA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
