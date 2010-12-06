package AdministratorDB::Schema::Component;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("component");
__PACKAGE__->add_columns(
  "component_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "component_name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 32,
  },
  "component_version",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 32,
  },
  "component_category",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 32,
  },
);
__PACKAGE__->set_primary_key("component_id");
__PACKAGE__->has_many(
  "component_installeds",
  "AdministratorDB::Schema::ComponentInstalled",
  { "foreign.component_id" => "self.component_id" },
);
__PACKAGE__->has_many(
  "component_instances",
  "AdministratorDB::Schema::ComponentInstance",
  { "foreign.component_id" => "self.component_id" },
);
__PACKAGE__->has_many(
  "component_provideds",
  "AdministratorDB::Schema::ComponentProvided",
  { "foreign.component_id" => "self.component_id" },
);
__PACKAGE__->has_many(
  "component_templates",
  "AdministratorDB::Schema::ComponentTemplate",
  { "foreign.component_id" => "self.component_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-12-06 14:01:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VzcvaHh2bTmFoOMJdL0psw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
