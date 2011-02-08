package AdministratorDB::Schema::Syslogng3Entry;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("syslogng3_entry");
__PACKAGE__->add_columns(
  "syslogng3_entry_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "syslogng3_entry_name",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "syslogng3_entry_type",
  { data_type => "ENUM", default_value => undef, is_nullable => 0, size => 11 },
  "syslogng3_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("syslogng3_entry_id");
__PACKAGE__->belongs_to(
  "syslogng3_id",
  "AdministratorDB::Schema::Syslogng3",
  { syslogng3_id => "syslogng3_id" },
);
__PACKAGE__->has_many(
  "syslogng3_entry_params",
  "AdministratorDB::Schema::Syslogng3EntryParam",
  { "foreign.syslogng3_entry_id" => "self.syslogng3_entry_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-02-07 12:23:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TE7DVuKCgIT8eLVcVAyNfA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
