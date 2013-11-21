use utf8;
package Kanopya::Schema::Result::ComponentTemplate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::ComponentTemplate

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

=head1 TABLE: C<component_template>

=cut

__PACKAGE__->table("component_template");

=head1 ACCESSORS

=head2 component_template_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 component_template_name

  data_type: 'char'
  is_nullable: 0
  size: 45

=head2 component_template_directory

  data_type: 'char'
  is_nullable: 0
  size: 45

=head2 component_type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "component_template_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "component_template_name",
  { data_type => "char", is_nullable => 0, size => 45 },
  "component_template_directory",
  { data_type => "char", is_nullable => 0, size => 45 },
  "component_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</component_template_id>

=back

=cut

__PACKAGE__->set_primary_key("component_template_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<component_template_name>

=over 4

=item * L</component_template_name>

=back

=cut

__PACKAGE__->add_unique_constraint("component_template_name", ["component_template_name"]);

=head1 RELATIONS

=head2 component_template_attr

Type: might_have

Related object: L<Kanopya::Schema::Result::ComponentTemplateAttr>

=cut

__PACKAGE__->might_have(
  "component_template_attr",
  "Kanopya::Schema::Result::ComponentTemplateAttr",
  { "foreign.template_component_id" => "self.component_template_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 component_type

Type: belongs_to

Related object: L<Kanopya::Schema::Result::ComponentType>

=cut

__PACKAGE__->belongs_to(
  "component_type",
  "Kanopya::Schema::Result::ComponentType",
  { component_type_id => "component_type_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 components

Type: has_many

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->has_many(
  "components",
  "Kanopya::Schema::Result::Component",
  { "foreign.component_template_id" => "self.component_template_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Izy+l2uH61LSgL7TZk8RSQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
