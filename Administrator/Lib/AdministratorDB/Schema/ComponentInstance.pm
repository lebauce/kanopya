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
  "component_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "component_template_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("component_instance_id");
__PACKAGE__->has_many(
  "apache2s",
  "AdministratorDB::Schema::Apache2",
  { "foreign.component_instance_id" => "self.component_instance_id" },
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
__PACKAGE__->belongs_to(
  "component_id",
  "AdministratorDB::Schema::Component",
  { component_id => "component_id" },
);
__PACKAGE__->has_many(
  "component_instance_entities",
  "AdministratorDB::Schema::ComponentInstanceEntity",
  { "foreign.component_instance_id" => "self.component_instance_id" },
);
__PACKAGE__->has_many(
  "lvm2_vgs",
  "AdministratorDB::Schema::Lvm2Vg",
  { "foreign.component_instance_id" => "self.component_instance_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-08-08 12:34:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:O2/DfF9zjldEaZcshj1OBw


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::ComponentInstanceEntity",
  { "foreign.component_instance_id" => "self.component_instance_id" },
);

1;
