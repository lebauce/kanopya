use utf8;
package AdministratorDB::Schema::Result::ComponentCategory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::ComponentCategory

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

=head1 TABLE: C<component_category>

=cut

__PACKAGE__->table("component_category");

=head1 ACCESSORS

=head2 component_category_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 category_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "component_category_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "category_name",
  { data_type => "char", is_nullable => 0, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</component_category_id>

=back

=cut

__PACKAGE__->set_primary_key("component_category_id");

=head1 RELATIONS

=head2 component_type_categories

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ComponentTypeCategory>

=cut

__PACKAGE__->has_many(
  "component_type_categories",
  "AdministratorDB::Schema::Result::ComponentTypeCategory",
  { "foreign.component_category_id" => "self.component_category_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 manager_category

Type: might_have

Related object: L<AdministratorDB::Schema::Result::ManagerCategory>

=cut

__PACKAGE__->might_have(
  "manager_category",
  "AdministratorDB::Schema::Result::ManagerCategory",
  { "foreign.manager_category_id" => "self.component_category_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 component_types

Type: many_to_many

Composing rels: L</component_type_categories> -> component_type

=cut

__PACKAGE__->many_to_many(
  "component_types",
  "component_type_categories",
  "component_type",
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2013-01-31 11:35:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:n4gXeCLs8WASczWCaKfJrQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
