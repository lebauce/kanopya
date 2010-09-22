package AdministratorDB::Schema::Apache2;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("apache2");
__PACKAGE__->add_columns(
  "component_instance_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "apache2_serverroot",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 64 },
  "apache2_loglevel",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 64 },
  "apache2_ports",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "apache2_sslports",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "apache2_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("apache2_id");
__PACKAGE__->belongs_to(
  "component_instance_id",
  "AdministratorDB::Schema::ComponentInstance",
  { "component_instance_id" => "component_instance_id" },
);
__PACKAGE__->has_many(
  "apache2_virtualhosts",
  "AdministratorDB::Schema::Apache2Virtualhost",
  { "foreign.apache2_id" => "self.apache2_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-09-22 11:46:12
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FF0bRHTj+bgqgzz9tngRBg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
