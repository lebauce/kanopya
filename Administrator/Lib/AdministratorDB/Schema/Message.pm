package AdministratorDB::Schema::Message;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("message");
__PACKAGE__->add_columns(
  "message_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "user_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 8 },
  "message_creationdate",
  { data_type => "DATE", default_value => undef, is_nullable => 0, size => 10 },
  "message_creationtime",
  { data_type => "TIME", default_value => undef, is_nullable => 0, size => 8 },
  "message_type",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "message_content",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("message_id");
__PACKAGE__->belongs_to(
  "user_id",
  "AdministratorDB::Schema::User",
  { user_id => "user_id" },
);
__PACKAGE__->has_many(
  "message_entities",
  "AdministratorDB::Schema::MessageEntity",
  { "foreign.message_id" => "self.message_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-08-24 00:51:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jnkxcwFbyhg7PRjBGE8jGg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
