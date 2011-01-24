package AdministratorDB::Schema::Entityright;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("entityright");
__PACKAGE__->add_columns(
  "entityright_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "entityright_consumed_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "entityright_consumer_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "entityright_method",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 64 },
);
__PACKAGE__->set_primary_key("entityright_id");
__PACKAGE__->add_unique_constraint(
  "entityright_right",
  [
    "entityright_consumed_id",
    "entityright_consumer_id",
    "entityright_method",
  ],
);
__PACKAGE__->belongs_to(
  "entityright_consumed_id",
  "AdministratorDB::Schema::Entity",
  { entity_id => "entityright_consumed_id" },
);
__PACKAGE__->belongs_to(
  "entityright_consumer_id",
  "AdministratorDB::Schema::Entity",
  { entity_id => "entityright_consumer_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-01-24 15:03:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cvGfo1OhYJgTkulR0K9vRg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
