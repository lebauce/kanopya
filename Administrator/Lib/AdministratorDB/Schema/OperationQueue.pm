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
  "user_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
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
__PACKAGE__->belongs_to(
  "user_id",
  "AdministratorDB::Schema::User",
  { user_id => "user_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-07-19 01:22:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rh14+Q/JZ+jrTJGdlXFQ1w


#
# Enable automatic date handling
#
__PACKAGE__->add_columns(
        "created",
        { data_type => 'datetime', set_on_create => 1 },
        "updated",
        { data_type => 'datetime', set_on_create => 1, set_on_update => 1 },
);
    
1;
