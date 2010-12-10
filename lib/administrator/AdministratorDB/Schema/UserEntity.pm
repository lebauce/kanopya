package AdministratorDB::Schema::UserEntity;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("user_entity");
__PACKAGE__->add_columns(
  "entity_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "user_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("entity_id", "user_id");
__PACKAGE__->add_unique_constraint("fk_user_entity_2", ["user_id"]);
__PACKAGE__->add_unique_constraint("fk_user_entity_1", ["entity_id"]);
__PACKAGE__->belongs_to(
  "entity_id",
  "AdministratorDB::Schema::Entity",
  { entity_id => "entity_id" },
);
__PACKAGE__->belongs_to(
  "user_id",
  "AdministratorDB::Schema::User",
  { user_id => "user_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-12-08 16:36:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2rHcZFvpMdyoLb8P23I9qw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
