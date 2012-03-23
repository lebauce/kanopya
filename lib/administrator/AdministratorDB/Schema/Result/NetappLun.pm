package AdministratorDB::Schema::Result::NetappLun;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::NetappLun

=cut

__PACKAGE__->table("netapp_lun");

=head1 ACCESSORS

=head2 lun_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 volume_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 size

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 filesystem

  data_type: 'char'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "lun_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "volume_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "char", is_nullable => 0, size => 255 },
  "size",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "filesystem",
  { data_type => "char", is_nullable => 0, size => 32 },
);
__PACKAGE__->set_primary_key("lun_id");

=head1 RELATIONS

=head2 lun

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Container>

=cut

__PACKAGE__->belongs_to(
  "lun",
  "AdministratorDB::Schema::Result::Container",
  { container_id => "lun_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 volume

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::NetappVolume>

=cut

__PACKAGE__->belongs_to(
  "volume",
  "AdministratorDB::Schema::Result::NetappVolume",
  { volume_id => "volume_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-03-12 11:00:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IUbdDi73piU2MieBPVEW6w


# You can replace this text with custom content, and it will be preserved on regeneration

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Container",
    { "foreign.container_id" => "self.lun_id" },
    { cascade_copy => 0, cascade_delete => 1 });

1;
