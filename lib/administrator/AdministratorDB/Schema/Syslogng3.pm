package AdministratorDB::Schema::Syslogng3;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("syslogng3");
__PACKAGE__->add_columns(
  "syslogng3_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "component_instance_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("syslogng3_id");
__PACKAGE__->belongs_to(
  "component_instance_id",
  "AdministratorDB::Schema::ComponentInstance",
  { "component_instance_id" => "component_instance_id" },
);
__PACKAGE__->has_many(
  "syslogng3_entries",
  "AdministratorDB::Schema::Syslogng3Entry",
  { "foreign.syslogng3_id" => "self.syslogng3_id" },
);
__PACKAGE__->has_many(
  "syslogng3_logs",
  "AdministratorDB::Schema::Syslogng3Log",
  { "foreign.syslogng3_id" => "self.syslogng3_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-02-07 12:23:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hO2/43GpyjsSDMI7xdllyA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
