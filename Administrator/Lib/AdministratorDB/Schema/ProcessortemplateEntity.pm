package AdministratorDB::Schema::ProcessortemplateEntity;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("processortemplate_entity");
__PACKAGE__->add_columns(
  "entity_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "processortemplate_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("entity_id", "processortemplate_id");
__PACKAGE__->add_unique_constraint("fk_processortemplate_entity_2", ["processortemplate_id"]);
__PACKAGE__->add_unique_constraint("fk_processortemplate_entity_1", ["entity_id"]);
__PACKAGE__->belongs_to(
  "entity_id",
  "AdministratorDB::Schema::Entity",
  { entity_id => "entity_id" },
);
__PACKAGE__->belongs_to(
  "processortemplate_id",
  "AdministratorDB::Schema::Processortemplate",
  { processortemplate_id => "processortemplate_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-07-21 19:05:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iAsZqWdNdrCXfpKWz7VVEQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
