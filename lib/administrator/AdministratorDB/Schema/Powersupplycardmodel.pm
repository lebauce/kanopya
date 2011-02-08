package AdministratorDB::Schema::Powersupplycardmodel;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("powersupplycardmodel");
__PACKAGE__->add_columns(
  "powersupplycardmodel_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "powersupplycardmodel_brand",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 64 },
  "powersupplycardmodel_name",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "powersupplycardmodel_slotscount",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 2 },
);
__PACKAGE__->set_primary_key("powersupplycardmodel_id");
__PACKAGE__->add_unique_constraint(
  "powersupplycardmodel_name_UNIQUE",
  ["powersupplycardmodel_name"],
);
__PACKAGE__->has_many(
  "powersupplycards",
  "AdministratorDB::Schema::Powersupplycard",
  {
    "foreign.powersupplycardmodel_id" => "self.powersupplycardmodel_id",
  },
);
__PACKAGE__->has_many(
  "powersupplycardmodel_entities",
  "AdministratorDB::Schema::PowersupplycardmodelEntity",
  {
    "foreign.powersupplycardmodel_id" => "self.powersupplycardmodel_id",
  },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-02-07 12:23:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Uca5QDKeKSMKQxNhOwkxdA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
