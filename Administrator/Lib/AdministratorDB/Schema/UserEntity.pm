package AdministratorDB::Schema::UserEntity;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("user_entity");
__PACKAGE__->add_columns(
  "entity_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "user_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
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


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-07-18 17:28:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JeV2bIaKlFhSCz5l6iNXvA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
