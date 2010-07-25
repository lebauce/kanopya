package AdministratorDB::Schema::ComponentInstance;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("component_instance");
__PACKAGE__->add_columns(
  "component_instance_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "cluster_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "component_type_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "component_template_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("component_instance_id");
__PACKAGE__->belongs_to(
  "component_type_id",
  "AdministratorDB::Schema::ComponentType",
  { component_type_id => "component_type_id" },
);
__PACKAGE__->belongs_to(
  "cluster_id",
  "AdministratorDB::Schema::Cluster",
  { cluster_id => "cluster_id" },
);
__PACKAGE__->belongs_to(
  "component_template_id",
  "AdministratorDB::Schema::ComponentTemplate",
  { "component_template_id" => "component_template_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-07-25 16:35:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bOOeOfBkSYFWd3PqcMGNPA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
