package AdministratorDB::Schema::KernelEntity;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("kernel_entity");
__PACKAGE__->add_columns(
  "entity_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "kernel_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("entity_id", "kernel_id");
__PACKAGE__->add_unique_constraint("fk_kernel_entity_1", ["entity_id"]);
__PACKAGE__->add_unique_constraint("fk_kernel_entity_2", ["kernel_id"]);
__PACKAGE__->belongs_to(
  "entity_id",
  "AdministratorDB::Schema::Entity",
  { entity_id => "entity_id" },
);
__PACKAGE__->belongs_to(
  "kernel_id",
  "AdministratorDB::Schema::Kernel",
  { kernel_id => "kernel_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-09-07 14:38:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jqctdDzbd8uJ6Nr4WF59Ew


# You can replace this text with custom content, and it will be preserved on regeneration
1;
