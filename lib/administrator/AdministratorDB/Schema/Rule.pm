package AdministratorDB::Schema::Rule;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("rule");
__PACKAGE__->add_columns(
  "rule_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "rule_condition",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 128 },
  "rule_action",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "cluster_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("rule_id");
__PACKAGE__->belongs_to(
  "cluster_id",
  "AdministratorDB::Schema::Cluster",
  { cluster_id => "cluster_id" },
);
__PACKAGE__->has_many(
  "ruleconditions",
  "AdministratorDB::Schema::Rulecondition",
  { "foreign.rule_id" => "self.rule_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-01-24 15:03:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:U/OaoSqniywePNEvifxP9Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
