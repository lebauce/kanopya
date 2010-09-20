package AdministratorDB::Schema::Atftpd0;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("atftpd0");
__PACKAGE__->add_columns(
  "atftpd0_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "component_instance_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "atftpd0_options",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 128 },
  "atftpd0_use_inetd",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 32 },
  "atftpd0_logfile",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 128 },
  "atftpd0_repository",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 64 },
);
__PACKAGE__->set_primary_key("atftpd0_id");
__PACKAGE__->belongs_to(
  "component_instance_id",
  "AdministratorDB::Schema::ComponentInstance",
  { "component_instance_id" => "component_instance_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-09-17 14:10:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fUMGVN3ke2ptuZanR/8AHw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
