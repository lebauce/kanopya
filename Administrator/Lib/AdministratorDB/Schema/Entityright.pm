package AdministratorDB::Schema::Entityright;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("entityright");
__PACKAGE__->add_columns(
  "entityright_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "entityright_entity_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "entityright_consumer_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "entityright_access",
  { data_type => "BIT", default_value => undef, is_nullable => 0, size => undef },
  "entityright_read",
  { data_type => "BIT", default_value => undef, is_nullable => 0, size => undef },
  "entityright_write",
  { data_type => "BIT", default_value => undef, is_nullable => 0, size => undef },
  "entityright_exec",
  { data_type => "BIT", default_value => undef, is_nullable => 0, size => undef },
  "entityright_admin",
  { data_type => "BIT", default_value => undef, is_nullable => 0, size => undef },
);
__PACKAGE__->set_primary_key("entityright_id");
__PACKAGE__->belongs_to(
  "entityright_entity_id",
  "AdministratorDB::Schema::Entity",
  { entity_id => "entityright_entity_id" },
);
__PACKAGE__->belongs_to(
  "entityright_consumer_id",
  "AdministratorDB::Schema::Entity",
  { entity_id => "entityright_consumer_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-07-21 19:05:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fSmTxd6Wpm/iqJE+ywj4fg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
