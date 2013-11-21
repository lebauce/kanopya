use utf8;
package Kanopya::Schema::Result::Systemimage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Systemimage

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<DBIx::Class::IntrospectableM2M>

=cut

use base 'DBIx::Class::IntrospectableM2M';

=head1 LEFT BASE CLASSES

=over 4

=item * L<DBIx::Class::Core>

=back

=cut

use base qw/DBIx::Class::Core/;

=head1 TABLE: C<systemimage>

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

=head2 active

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 service_provider_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
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
  "active",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "service_provider_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</systemimage_id>

=back

=cut

__PACKAGE__->set_primary_key("systemimage_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<systemimage_name>

=over 4

=item * L</systemimage_name>

=back

=cut

__PACKAGE__->add_unique_constraint("systemimage_name", ["systemimage_name"]);

=head1 RELATIONS

=head2 components_installed

Type: has_many

Related object: L<Kanopya::Schema::Result::ComponentInstalled>

=cut

__PACKAGE__->has_many(
  "components_installed",
  "Kanopya::Schema::Result::ComponentInstalled",
  { "foreign.systemimage_id" => "self.systemimage_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nodes

Type: has_many

Related object: L<Kanopya::Schema::Result::Node>

=cut

__PACKAGE__->has_many(
  "nodes",
  "Kanopya::Schema::Result::Node",
  { "foreign.systemimage_id" => "self.systemimage_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_provider

Type: belongs_to

Related object: L<Kanopya::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "service_provider",
  "Kanopya::Schema::Result::ServiceProvider",
  { service_provider_id => "service_provider_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 systemimage

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "systemimage",
  "Kanopya::Schema::Result::Entity",
  { entity_id => "systemimage_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 systemimage_container_accesses

Type: has_many

Related object: L<Kanopya::Schema::Result::SystemimageContainerAccess>

=cut

__PACKAGE__->has_many(
  "systemimage_container_accesses",
  "Kanopya::Schema::Result::SystemimageContainerAccess",
  { "foreign.systemimage_id" => "self.systemimage_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 component_types

Type: many_to_many

Composing rels: L</components_installed> -> component_type

=cut

__PACKAGE__->many_to_many("component_types", "components_installed", "component_type");

=head2 container_accesses

Type: many_to_many

Composing rels: L</systemimage_container_accesses> -> container_access

=cut

__PACKAGE__->many_to_many(
  "container_accesses",
  "systemimage_container_accesses",
  "container_access",
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GStoXyqhmPtUj7txmOQCbQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
