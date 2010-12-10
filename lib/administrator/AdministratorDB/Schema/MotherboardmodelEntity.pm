package AdministratorDB::Schema::MotherboardmodelEntity;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("motherboardmodel_entity");
__PACKAGE__->add_columns(
  "entity_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "motherboardmodel_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("entity_id", "motherboardmodel_id");
__PACKAGE__->add_unique_constraint("fk_motherboardmodel_entity_1", ["entity_id"]);
__PACKAGE__->add_unique_constraint("fk_motherboardmodel_entity_2", ["motherboardmodel_id"]);
__PACKAGE__->belongs_to(
  "entity_id",
  "AdministratorDB::Schema::Entity",
  { entity_id => "entity_id" },
);
__PACKAGE__->belongs_to(
  "motherboardmodel_id",
  "AdministratorDB::Schema::Motherboardmodel",
  { motherboardmodel_id => "motherboardmodel_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-12-10 10:34:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7ilvaIVyyP89/IK3kzc0gg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
