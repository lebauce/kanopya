package AdministratorDB::Schema::Result::ComponentTemplate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::ComponentTemplate

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
__PACKAGE__->set_primary_key("component_template_id");
__PACKAGE__->add_unique_constraint("component_template_name", ["component_template_name"]);

=head1 RELATIONS

=head2 components

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->has_many(
  "components",
  "AdministratorDB::Schema::Result::Component",
  { "foreign.component_template_id" => "self.component_template_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 component_type

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ComponentType>

=cut

__PACKAGE__->belongs_to(
  "component_type",
  "AdministratorDB::Schema::Result::ComponentType",
  { component_type_id => "component_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 component_template_attr

Type: might_have

Related object: L<AdministratorDB::Schema::Result::ComponentTemplateAttr>

=cut

__PACKAGE__->might_have(
  "component_template_attr",
  "AdministratorDB::Schema::Result::ComponentTemplateAttr",
  { "foreign.template_component_id" => "self.component_template_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-02-02 10:20:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2CKn4OR8xcRDqYeidHGJhA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
