package AdministratorDB::Schema::Snmpd5;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("snmpd5");
__PACKAGE__->add_columns(
  "component_instance_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "snmpd5_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "monitor_server_ip",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 39 },
  "snmpd_options",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 128 },
);
__PACKAGE__->set_primary_key("snmpd5_id");
__PACKAGE__->belongs_to(
  "component_instance_id",
  "AdministratorDB::Schema::ComponentInstance",
  { "component_instance_id" => "component_instance_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-02-08 12:50:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OFoj5Ua2b6eOQL8nTs7OIA


# You can replace this text with custom content, and it will be preserved on regeneration


1;
