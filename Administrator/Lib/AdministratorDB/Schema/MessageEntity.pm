package AdministratorDB::Schema::MessageEntity;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("message_entity");
__PACKAGE__->add_columns(
  "entity_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "message_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("entity_id", "message_id");
__PACKAGE__->add_unique_constraint("fk_message_entity_2", ["message_id"]);
__PACKAGE__->add_unique_constraint("fk_message_entity_1", ["entity_id"]);
__PACKAGE__->belongs_to(
  "entity_id",
  "AdministratorDB::Schema::Entity",
  { entity_id => "entity_id" },
);
__PACKAGE__->belongs_to(
  "message_id",
  "AdministratorDB::Schema::Message",
  { message_id => "message_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-08-20 14:40:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:t+a/4N2Q7/v4QyTCGh3FSg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
