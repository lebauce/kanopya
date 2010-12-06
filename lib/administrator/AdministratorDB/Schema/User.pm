package AdministratorDB::Schema::User;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("user");
__PACKAGE__->add_columns(
  "user_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "user_system",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 1 },
  "user_login",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "user_password",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "user_firstname",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 64 },
  "user_lastname",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 64 },
  "user_email",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 255 },
  "user_creationdate",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "user_lastaccess",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => 19,
  },
  "user_desc",
  {
    data_type => "CHAR",
    default_value => "Note concerning this user",
    is_nullable => 1,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("user_id");
__PACKAGE__->add_unique_constraint("user_login", ["user_login"]);
__PACKAGE__->has_many(
  "messages",
  "AdministratorDB::Schema::Message",
  { "foreign.user_id" => "self.user_id" },
);
__PACKAGE__->has_many(
  "operations",
  "AdministratorDB::Schema::Operation",
  { "foreign.user_id" => "self.user_id" },
);
__PACKAGE__->has_many(
  "user_entities",
  "AdministratorDB::Schema::UserEntity",
  { "foreign.user_id" => "self.user_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-12-06 13:00:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fVNwRUPvG4n1SwJrsAEfIQ


# You can replace this text with custom content, and it will be preserved on regeneration

__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::UserEntity",
  { "foreign.user_id" => "self.user_id" },
);

1;
