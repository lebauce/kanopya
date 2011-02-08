package AdministratorDB::Schema::Apache2Virtualhost;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("apache2_virtualhost");
__PACKAGE__->add_columns(
  "apache2_virtualhost_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "apache2_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "apache2_virtualhost_servername",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 128 },
  "apache2_virtualhost_sslenable",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 1 },
  "apache2_virtualhost_serveradmin",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 64 },
  "apache2_virtualhost_documentroot",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 128 },
  "apache2_virtualhost_log",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 128 },
  "apache2_virtualhost_errorlog",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 45,
  },
);
__PACKAGE__->set_primary_key("apache2_virtualhost_id");
__PACKAGE__->belongs_to(
  "apache2_id",
  "AdministratorDB::Schema::Apache2",
  { apache2_id => "apache2_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-02-07 12:23:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FtD/ABrQYEWGoMhauMJpFQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
