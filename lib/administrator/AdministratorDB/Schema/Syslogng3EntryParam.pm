package AdministratorDB::Schema::Syslogng3EntryParam;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("syslogng3_entry_param");
__PACKAGE__->add_columns(
  "syslogng3_entry_param_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "syslogng3_entry_param_content",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 0,
    size => 65535,
  },
  "syslogng3_entry_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("syslogng3_entry_param_id");
__PACKAGE__->belongs_to(
  "syslogng3_entry_id",
  "AdministratorDB::Schema::Syslogng3Entry",
  { syslogng3_entry_id => "syslogng3_entry_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-02-08 12:50:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:O1tEpPfX6nNEaPtsoUvyBA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
