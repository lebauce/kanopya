package AdministratorDB::Schema::PowersupplycardEntity;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("powersupplycard_entity");
__PACKAGE__->add_columns(
  "entity_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "powersupplycard_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("entity_id", "powersupplycard_id");
__PACKAGE__->add_unique_constraint("fk_powersupplycard_entity_2", ["powersupplycard_id"]);
__PACKAGE__->add_unique_constraint("fk_powersupplycard_entity_1", ["entity_id"]);
__PACKAGE__->belongs_to(
  "entity_id",
  "AdministratorDB::Schema::Entity",
  { entity_id => "entity_id" },
);
__PACKAGE__->belongs_to(
  "powersupplycard_id",
  "AdministratorDB::Schema::Powersupplycard",
  { powersupplycard_id => "powersupplycard_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-12-06 14:01:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/3QgCE9iOsoyiGdtmCi1rA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
