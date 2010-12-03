package AdministratorDB::Schema::Powersupply;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("powersupply");
__PACKAGE__->add_columns(
  "powersupply_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "powersupplycard_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "powersupplyport_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("powersupply_id");
__PACKAGE__->has_many(
  "motherboards",
  "AdministratorDB::Schema::Motherboard",
  { "foreign.motherboard_powersupply_id" => "self.powersupply_id" },
);
__PACKAGE__->belongs_to(
  "powersupplycard_id",
  "AdministratorDB::Schema::Powersupplycard",
  { powersupplycard_id => "powersupplycard_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-11-02 18:11:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9VmatA7m+l+U/FOSJmj22g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
