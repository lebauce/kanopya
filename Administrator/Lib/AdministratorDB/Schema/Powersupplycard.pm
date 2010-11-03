package AdministratorDB::Schema::Powersupplycard;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("powersupplycard");
__PACKAGE__->add_columns(
  "powersupplycard_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "powersupplycard_name",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 64 },
  "powersupplycard_ip",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 15 },
  "powersupplycard_model_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 8 },
  "powersupplycard_mac_address",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
);
__PACKAGE__->set_primary_key("powersupplycard_id");
__PACKAGE__->has_many(
  "powersupplies",
  "AdministratorDB::Schema::Powersupply",
  { "foreign.powersupplycard_id" => "self.powersupplycard_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-11-02 18:11:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WoVimP+97KO1NrEQAedWHQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
