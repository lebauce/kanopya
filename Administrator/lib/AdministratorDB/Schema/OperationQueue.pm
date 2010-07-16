package AdministratorDB::Schema::OperationQueue;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("operation_queue");
__PACKAGE__->add_columns(
  "operation_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "type",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 64 },
  "owner",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 64 },
  "priority",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 2 },
  "creation_date",
  { data_type => "DATE", default_value => undef, is_nullable => 0, size => 10 },
  "creation_time",
  { data_type => "TIME", default_value => undef, is_nullable => 0, size => 8 },
  "execution_rank",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("operation_id");
__PACKAGE__->add_unique_constraint("execution_rank_UNIQUE", ["execution_rank"]);
__PACKAGE__->has_many(
  "operation_parameters",
  "AdministratorDB::Schema::OperationParameter",
  { "foreign.operation_id" => "self.operation_id" },
);


#sub new {
	
#	print "====================> NEW !!!";

#}

# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-07-14 20:51:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iztEMu/xr2x4zWO8s8F1xA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
