package AdministratorDB::Schema::Result::Component;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Component

=cut

__PACKAGE__->table("component");

=head1 ACCESSORS

=head2 component_id

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
  "component_id",
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
__PACKAGE__->set_primary_key("component_id");

=head1 RELATIONS

=head2 components_installed

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ComponentInstalled>

=cut

__PACKAGE__->has_many(
  "components_installed",
  "AdministratorDB::Schema::Result::ComponentInstalled",
  { "foreign.component_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 component_instances

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ComponentInstance>

=cut

__PACKAGE__->has_many(
  "component_instances",
  "AdministratorDB::Schema::Result::ComponentInstance",
  { "foreign.component_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 components_provided

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ComponentProvided>

=cut

__PACKAGE__->has_many(
  "components_provided",
  "AdministratorDB::Schema::Result::ComponentProvided",
  { "foreign.component_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 component_templates

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ComponentTemplate>

=cut

__PACKAGE__->has_many(
  "component_templates",
  "AdministratorDB::Schema::Result::ComponentTemplate",
  { "foreign.component_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aDtVOsbwHK75tR9FEzI+xw


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
    { "foreign.entity_id" => "self.component_id" },
    { cascade_copy => 0, cascade_delete => 1 });
1;
