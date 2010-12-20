package AdministratorDB::Schema::MotherboardEntity;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("motherboard_entity");
__PACKAGE__->add_columns(
  "entity_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "motherboard_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("entity_id", "motherboard_id");
__PACKAGE__->add_unique_constraint("fk_motherboard_entity_2", ["motherboard_id"]);
__PACKAGE__->add_unique_constraint("fk_motherboard_entity_1", ["entity_id"]);
__PACKAGE__->belongs_to(
  "entity_id",
  "AdministratorDB::Schema::Entity",
  { entity_id => "entity_id" },
);
__PACKAGE__->belongs_to(
  "motherboard_id",
  "AdministratorDB::Schema::Motherboard",
  { motherboard_id => "motherboard_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-12-15 11:08:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AF28ZqtqxB5bcO7PG0ujBQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
