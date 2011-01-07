package AdministratorDB::Schema::ComponentInstanceEntity;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("component_instance_entity");
__PACKAGE__->add_columns(
  "entity_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "component_instance_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("entity_id", "component_instance_id");
__PACKAGE__->add_unique_constraint("fk_component_instance_entity_2", ["component_instance_id"]);
__PACKAGE__->add_unique_constraint("fk_component_instance_entity_1", ["entity_id"]);
__PACKAGE__->belongs_to(
  "entity_id",
  "AdministratorDB::Schema::Entity",
  { entity_id => "entity_id" },
);
__PACKAGE__->belongs_to(
  "component_instance_id",
  "AdministratorDB::Schema::ComponentInstance",
  { "component_instance_id" => "component_instance_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-01-07 16:32:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Vnnlrg4pK/hIPC/Qpi1pWw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
