package AdministratorDB::Schema::Result::Systemimage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Systemimage

=cut

__PACKAGE__->table("systemimage");

=head1 ACCESSORS

=head2 systemimage_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 systemimage_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 systemimage_desc

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 container_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 active

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "systemimage_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "systemimage_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "systemimage_desc",
  { data_type => "char", is_nullable => 1, size => 255 },
  "container_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "active",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("systemimage_id");
__PACKAGE__->add_unique_constraint("systemimage_name", ["systemimage_name"]);

=head1 RELATIONS

=head2 components_installed

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ComponentInstalled>

=cut

__PACKAGE__->has_many(
  "components_installed",
  "AdministratorDB::Schema::Result::ComponentInstalled",
  { "foreign.systemimage_id" => "self.systemimage_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nodes

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Node>

=cut

__PACKAGE__->has_many(
  "nodes",
  "AdministratorDB::Schema::Result::Node",
  { "foreign.systemimage_id" => "self.systemimage_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 systemimage

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "systemimage",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "systemimage_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 container

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Container>

=cut

__PACKAGE__->belongs_to(
  "container",
  "AdministratorDB::Schema::Result::Container",
  { container_id => "container_id" },
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-03-21 22:25:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7O7nWkC6XAyK+Gqtr9DyEg

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
  { "foreign.entity_id" => "self.systemimage_id" },
  { cascade_copy => 0, cascade_delete => 1 }
);

1;
