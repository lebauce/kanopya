package AdministratorDB::Schema::MotherboardModelEntity;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("motherboard_model_entity");
__PACKAGE__->add_columns(
  "entity_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "motherboard_model_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("entity_id", "motherboard_model_id");
__PACKAGE__->belongs_to(
  "entity_id",
  "AdministratorDB::Schema::Entity",
  { entity_id => "entity_id" },
);
__PACKAGE__->belongs_to(
  "motherboard_model_id",
  "AdministratorDB::Schema::MotherboardModel",
  { motherboard_model_id => "motherboard_model_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-08-08 12:34:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fRDyRvCqcBBOf+oKePfcBg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
