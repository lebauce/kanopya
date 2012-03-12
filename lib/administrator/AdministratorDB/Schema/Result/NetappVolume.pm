package AdministratorDB::Schema::Result::NetappVolume;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::NetappVolume

=cut

__PACKAGE__->table("netapp_volume");

=head1 ACCESSORS

=head2 volume_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 aggregate_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 name

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 size

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "volume_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "aggregate_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "name",
  { data_type => "char", is_nullable => 0, size => 255 },
  "size",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("volume_id");

=head1 RELATIONS

=head2 netapp_luns

Type: has_many

Related object: L<AdministratorDB::Schema::Result::NetappLun>

=cut

__PACKAGE__->has_many(
  "netapp_luns",
  "AdministratorDB::Schema::Result::NetappLun",
  { "foreign.volume_id" => "self.volume_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 volume

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Container>

=cut

__PACKAGE__->belongs_to(
  "volume",
  "AdministratorDB::Schema::Result::Container",
  { container_id => "volume_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-03-12 03:38:03
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6xcyHeM2yVzvywNceyY7IA


# You can replace this text with custom content, and it will be preserved on regeneration

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Container",
    { "foreign.container_id" => "self.volume_id" },
    { cascade_copy => 0, cascade_delete => 1 });

1;
