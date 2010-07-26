package AdministratorDB::Schema::ComponentType;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("component_type");
__PACKAGE__->add_columns(
  "component_type_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 45,
  },
  "version",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 45,
  },
  "category",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 45,
  },
);
__PACKAGE__->set_primary_key("component_type_id");
__PACKAGE__->has_many(
  "component_instances",
  "AdministratorDB::Schema::ComponentInstance",
  { "foreign.component_type_id" => "self.component_type_id" },
);
__PACKAGE__->has_many(
  "component_type_is_installeds",
  "AdministratorDB::Schema::ComponentTypeIsInstalled",
  { "foreign.component_type_id" => "self.component_type_id" },
);
__PACKAGE__->has_many(
  "distributionprovides",
  "AdministratorDB::Schema::Distributionprovides",
  { "foreign.componenttype_id" => "self.component_type_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-07-26 09:55:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4b718uvgny5ZlxTtQfBvEA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
