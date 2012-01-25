package AdministratorDB::Schema::Result::ComponentTemplateAttr;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::ComponentTemplateAttr

=cut

__PACKAGE__->table("component_template_attr");

=head1 ACCESSORS

=head2 template_component_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 template_component_attr_file

  data_type: 'char'
  is_nullable: 0
  size: 45

=head2 component_template_attr_field

  data_type: 'char'
  is_nullable: 0
  size: 45

=head2 component_template_attr_type

  data_type: 'char'
  is_nullable: 0
  size: 45

=cut

__PACKAGE__->add_columns(
  "template_component_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "template_component_attr_file",
  { data_type => "char", is_nullable => 0, size => 45 },
  "component_template_attr_field",
  { data_type => "char", is_nullable => 0, size => 45 },
  "component_template_attr_type",
  { data_type => "char", is_nullable => 0, size => 45 },
);
__PACKAGE__->set_primary_key("template_component_id");

=head1 RELATIONS

=head2 template_component

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ComponentTemplate>

=cut

__PACKAGE__->belongs_to(
  "template_component",
  "AdministratorDB::Schema::Result::ComponentTemplate",
  { component_template_id => "template_component_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-25 14:17:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Qg149hWUJFztMnwCQdZ1GQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
