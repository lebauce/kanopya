package AdministratorDB::Schema::Keepalived1Realserver;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("keepalived1_realserver");
__PACKAGE__->add_columns(
  "realserver_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "virtualserver_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "realserver_ip",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 39 },
  "realserver_port",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 2 },
  "realserver_weight",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 2 },
  "realserver_checkport",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 2 },
  "realserver_checktimeout",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 2 },
);
__PACKAGE__->set_primary_key("realserver_id");
__PACKAGE__->belongs_to(
  "virtualserver_id",
  "AdministratorDB::Schema::Keepalived1Virtualserver",
  { virtualserver_id => "virtualserver_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-12-15 11:08:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ccjC2F3u3798YbEG9yb8Cg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
