package AdministratorDB::Schema::Keepalived1Virtualserver;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("keepalived1_virtualserver");
__PACKAGE__->add_columns(
  "virtualserver_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "keepalived_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "virtualserver_ip",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 39 },
  "virtualserver_port",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 2 },
  "virtualserver_lbalgo",
  { data_type => "ENUM", default_value => "rr", is_nullable => 0, size => 4 },
  "virtualserver_lbkind",
  { data_type => "ENUM", default_value => "NAT", is_nullable => 0, size => 3 },
);
__PACKAGE__->set_primary_key("virtualserver_id");
__PACKAGE__->has_many(
  "keepalived1_realservers",
  "AdministratorDB::Schema::Keepalived1Realserver",
  { "foreign.virtualserver_id" => "self.virtualserver_id" },
);
__PACKAGE__->belongs_to(
  "keepalived_id",
  "AdministratorDB::Schema::Keepalived1",
  { keepalived_id => "keepalived_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-12-06 19:03:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2zQjLSX6FFXd9RkjOdcw1A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
