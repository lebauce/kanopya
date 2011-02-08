package AdministratorDB::Schema::Syslogng3Log;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("syslogng3_log");
__PACKAGE__->add_columns(
  "syslogng3_log_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "syslogng3_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("syslogng3_log_id");
__PACKAGE__->belongs_to(
  "syslogng3_id",
  "AdministratorDB::Schema::Syslogng3",
  { syslogng3_id => "syslogng3_id" },
);
__PACKAGE__->has_many(
  "syslogng3_log_params",
  "AdministratorDB::Schema::Syslogng3LogParam",
  { "foreign.syslogng3_log_id" => "self.syslogng3_log_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-02-08 12:50:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vBYA3V5CPtKnk16KsWcwSA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
