package AdministratorDB::Schema::ProcessormodelEntity;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("processormodel_entity");
__PACKAGE__->add_columns(
  "entity_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "processormodel_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("entity_id", "processormodel_id");
__PACKAGE__->add_unique_constraint("fk_processormodel_entity_1", ["entity_id"]);
__PACKAGE__->add_unique_constraint("fk_processormodel_entity_2", ["processormodel_id"]);
__PACKAGE__->belongs_to(
  "entity_id",
  "AdministratorDB::Schema::Entity",
  { entity_id => "entity_id" },
);
__PACKAGE__->belongs_to(
  "processormodel_id",
  "AdministratorDB::Schema::Processormodel",
  { processormodel_id => "processormodel_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-02-03 13:34:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KN6ueX16XfLGjJlnS6TNEA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
