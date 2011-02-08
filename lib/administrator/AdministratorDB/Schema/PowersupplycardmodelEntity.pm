package AdministratorDB::Schema::PowersupplycardmodelEntity;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("powersupplycardmodel_entity");
__PACKAGE__->add_columns(
  "entity_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "powersupplycardmodel_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("entity_id", "powersupplycardmodel_id");
__PACKAGE__->add_unique_constraint("fk_powersupplycardmodel_entity_1", ["entity_id"]);
__PACKAGE__->add_unique_constraint(
  "fk_powersupplycardmodel_entity_2",
  ["powersupplycardmodel_id"],
);
__PACKAGE__->belongs_to(
  "entity_id",
  "AdministratorDB::Schema::Entity",
  { entity_id => "entity_id" },
);
__PACKAGE__->belongs_to(
  "powersupplycardmodel_id",
  "AdministratorDB::Schema::Powersupplycardmodel",
  { "powersupplycardmodel_id" => "powersupplycardmodel_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-02-08 12:50:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xL3aWJd77Rb7+DotLSbGnw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
