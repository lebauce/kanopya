package AdministratorDB::Schema::Kernel;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("kernel");
__PACKAGE__->add_columns(
  "kernel_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "kernel_name",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 64 },
  "kernel_version",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "kernel_desc",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("kernel_id");
__PACKAGE__->has_many(
  "kernel_entities",
  "AdministratorDB::Schema::KernelEntity",
  { "foreign.kernel_id" => "self.kernel_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-07-26 09:55:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:l9JH96DnyNNq8fusGLNNSQ


# You can replace this text with custom content, and it will be preserved on regeneration

__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::KernelEntity",
  { "foreign.kernel_id" => "self.kernel_id" },
);


1;
