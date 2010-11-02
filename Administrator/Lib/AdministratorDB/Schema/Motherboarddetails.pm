package AdministratorDB::Schema::Motherboarddetails;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("motherboarddetails");
__PACKAGE__->add_columns(
  "motherboard_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "name",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "value",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("motherboard_id", "name");
__PACKAGE__->belongs_to(
  "motherboard_id",
  "AdministratorDB::Schema::Motherboard",
  { motherboard_id => "motherboard_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-11-02 18:11:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pxsY7pG35OvvBk0ItGahfQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
