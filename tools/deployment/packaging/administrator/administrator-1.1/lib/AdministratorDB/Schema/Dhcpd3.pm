package AdministratorDB::Schema::Dhcpd3;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("dhcpd3");
__PACKAGE__->add_columns(
  "dhcpd3_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "component_instance_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "dhcpd3_domain_name",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 128 },
  "dhcpd3_domain_server",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 128 },
  "dhcpd3_servername",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 128 },
);
__PACKAGE__->set_primary_key("dhcpd3_id");
__PACKAGE__->belongs_to(
  "component_instance_id",
  "AdministratorDB::Schema::ComponentInstance",
  { "component_instance_id" => "component_instance_id" },
);
__PACKAGE__->has_many(
  "dhcpd3_subnets",
  "AdministratorDB::Schema::Dhcpd3Subnet",
  { "foreign.dhcpd3_id" => "self.dhcpd3_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-11-02 18:11:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8ISE6GzMDfjkX/6XpRlm9w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
