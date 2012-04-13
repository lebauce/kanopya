package AdministratorDB::Schema::Result::ComponentType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::ComponentType

=cut

__PACKAGE__->table("component_type");

=head1 ACCESSORS

=head2 component_type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 component_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 component_version

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 component_category

  data_type: 'char'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "component_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "component_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "component_version",
  { data_type => "char", is_nullable => 0, size => 32 },
  "component_category",
  { data_type => "char", is_nullable => 0, size => 32 },
);
__PACKAGE__->set_primary_key("component_type_id");

=head1 RELATIONS

=head2 components

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->has_many(
  "components",
  "AdministratorDB::Schema::Result::Component",
  { "foreign.component_type_id" => "self.component_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 components_installed

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ComponentInstalled>

=cut

__PACKAGE__->has_many(
  "components_installed",
  "AdministratorDB::Schema::Result::ComponentInstalled",
  { "foreign.component_type_id" => "self.component_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 components_provided

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ComponentProvided>

=cut

__PACKAGE__->has_many(
  "components_provided",
  "AdministratorDB::Schema::Result::ComponentProvided",
  { "foreign.component_type_id" => "self.component_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 component_templates

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ComponentTemplate>

=cut

__PACKAGE__->has_many(
  "component_templates",
  "AdministratorDB::Schema::Result::ComponentTemplate",
  { "foreign.component_type_id" => "self.component_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-26 16:29:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fGE3vPAXkZXFXbJISsI/8A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
