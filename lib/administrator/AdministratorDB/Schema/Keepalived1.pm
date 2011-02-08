package AdministratorDB::Schema::Keepalived1;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("keepalived1");
__PACKAGE__->add_columns(
  "keepalived_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "component_instance_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "daemon_method",
  { data_type => "ENUM", default_value => "master", is_nullable => 0, size => 6 },
  "iface",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 64 },
  "notification_email",
  {
    data_type => "CHAR",
    default_value => "admin\@hedera-technology.com",
    is_nullable => 1,
    size => 255,
  },
  "notification_email_from",
  {
    data_type => "CHAR",
    default_value => "keepalived\@some-cluster.com",
    is_nullable => 1,
    size => 255,
  },
  "smtp_server",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 39 },
  "smtp_connect_timeout",
  { data_type => "INT", default_value => 30, is_nullable => 0, size => 2 },
  "lvs_id",
  {
    data_type => "CHAR",
    default_value => "MAIN_LVS",
    is_nullable => 0,
    size => 32,
  },
);
__PACKAGE__->set_primary_key("keepalived_id");
__PACKAGE__->add_unique_constraint("fk_keepalived1_1", ["component_instance_id"]);
__PACKAGE__->belongs_to(
  "component_instance_id",
  "AdministratorDB::Schema::ComponentInstance",
  { "component_instance_id" => "component_instance_id" },
);
__PACKAGE__->has_many(
  "keepalived1_virtualservers",
  "AdministratorDB::Schema::Keepalived1Virtualserver",
  { "foreign.keepalived_id" => "self.keepalived_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-02-08 12:50:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Kq44XcinLouCEIkPbrghnw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
