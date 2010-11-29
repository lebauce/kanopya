package AdministratorDB::Schema::Dhcpd3details;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("dhcpd3details");
__PACKAGE__->add_columns(
  "dhcpd3_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "name",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "value",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 255 },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-08-20 14:40:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ES2/MW+HBOOiKfnrjjz/tg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
