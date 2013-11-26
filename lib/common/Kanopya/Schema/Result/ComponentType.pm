use utf8;
package Kanopya::Schema::Result::ComponentType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::ComponentType

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

=head1 TABLE: C<component_type>

=cut

__PACKAGE__->table("component_type");

=head1 ACCESSORS

=head2 component_type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 component_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 component_version

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 deployable

  data_type: 'integer'
  default_value: 1
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "component_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "component_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "component_version",
  { data_type => "char", is_nullable => 0, size => 32 },
  "deployable",
  {
    data_type => "integer",
    default_value => 1,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</component_type_id>

=back

=cut

__PACKAGE__->set_primary_key("component_type_id");

=head1 RELATIONS

=head2 component_templates

Type: has_many

Related object: L<Kanopya::Schema::Result::ComponentTemplate>

=cut

__PACKAGE__->has_many(
  "component_templates",
  "Kanopya::Schema::Result::ComponentTemplate",
  { "foreign.component_type_id" => "self.component_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 component_type

Type: belongs_to

Related object: L<Kanopya::Schema::Result::ClassType>

=cut

__PACKAGE__->belongs_to(
  "component_type",
  "Kanopya::Schema::Result::ClassType",
  { class_type_id => "component_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 component_type_categories

Type: has_many

Related object: L<Kanopya::Schema::Result::ComponentTypeCategory>

=cut

__PACKAGE__->has_many(
  "component_type_categories",
  "Kanopya::Schema::Result::ComponentTypeCategory",
  { "foreign.component_type_id" => "self.component_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 components

Type: has_many

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->has_many(
  "components",
  "Kanopya::Schema::Result::Component",
  { "foreign.component_type_id" => "self.component_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 components_installed

Type: has_many

Related object: L<Kanopya::Schema::Result::ComponentInstalled>

=cut

__PACKAGE__->has_many(
  "components_installed",
  "Kanopya::Schema::Result::ComponentInstalled",
  { "foreign.component_type_id" => "self.component_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 components_provided

Type: has_many

Related object: L<Kanopya::Schema::Result::ComponentProvided>

=cut

__PACKAGE__->has_many(
  "components_provided",
  "Kanopya::Schema::Result::ComponentProvided",
  { "foreign.component_type_id" => "self.component_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_provider_type_component_types

Type: has_many

Related object: L<Kanopya::Schema::Result::ServiceProviderTypeComponentType>

=cut

__PACKAGE__->has_many(
  "service_provider_type_component_types",
  "Kanopya::Schema::Result::ServiceProviderTypeComponentType",
  { "foreign.component_type_id" => "self.component_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 component_categories

Type: many_to_many

Composing rels: L</component_type_categories> -> component_category

=cut

__PACKAGE__->many_to_many(
  "component_categories",
  "component_type_categories",
  "component_category",
);

=head2 masterimages

Type: many_to_many

Composing rels: L</components_provided> -> masterimage

=cut

__PACKAGE__->many_to_many("masterimages", "components_provided", "masterimage");

=head2 service_provider_types

Type: many_to_many

Composing rels: L</service_provider_type_component_types> -> service_provider_type

=cut

__PACKAGE__->many_to_many(
  "service_provider_types",
  "service_provider_type_component_types",
  "service_provider_type",
);

=head2 systemimages

Type: many_to_many

Composing rels: L</components_installed> -> systemimage

=cut

__PACKAGE__->many_to_many("systemimages", "components_installed", "systemimage");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-25 10:39:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UUTRY2xqQklWrn4AqZ6puw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
