package AdministratorDB::Schema::Distributionprovides;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("distributionprovides");
__PACKAGE__->add_columns(
  "distribution_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "componenttype_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("distribution_id", "componenttype_id");
__PACKAGE__->belongs_to(
  "componenttype_id",
  "AdministratorDB::Schema::ComponentType",
  { component_type_id => "componenttype_id" },
);
__PACKAGE__->belongs_to(
  "distribution_id",
  "AdministratorDB::Schema::Distribution",
  { distribution_id => "distribution_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-07-25 16:35:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CeSvrfDTqQDbUqT08meOow


# You can replace this text with custom content, and it will be preserved on regeneration
1;
