package AdministratorDB::Schema::ComponentTemplate;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("component_template");
__PACKAGE__->add_columns(
  "component_template_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "component_template_name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 45,
  },
  "component_template_directory",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 45,
  },
);
__PACKAGE__->set_primary_key("component_template_id");
__PACKAGE__->add_unique_constraint("component_template_UNIQUE", ["component_template_name"]);
__PACKAGE__->has_many(
  "component_instances",
  "AdministratorDB::Schema::ComponentInstance",
  { "foreign.component_template_id" => "self.component_template_id" },
);
__PACKAGE__->has_many(
  "component_template_attrs",
  "AdministratorDB::Schema::ComponentTemplateAttr",
  { "foreign.template_component_id" => "self.component_template_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-08-16 15:45:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LWJJKV2fsN1XKmFkXN/2Ng


# You can replace this text with custom content, and it will be preserved on regeneration
1;
