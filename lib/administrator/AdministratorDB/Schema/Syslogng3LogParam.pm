package AdministratorDB::Schema::Syslogng3LogParam;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("syslogng3_log_param");
__PACKAGE__->add_columns(
  "syslogng3_log_param_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "syslogng3_log_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "syslogng3_log_param_entrytype",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "syslogng3_log_param_entryname",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
);
__PACKAGE__->set_primary_key("syslogng3_log_param_id");
__PACKAGE__->belongs_to(
  "syslogng3_log_id",
  "AdministratorDB::Schema::Syslogng3Log",
  { syslogng3_log_id => "syslogng3_log_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-02-08 12:50:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XxYGU1ZqLai4OU/R04bqcA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
