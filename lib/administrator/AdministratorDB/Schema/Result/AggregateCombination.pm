package AdministratorDB::Schema::Result::AggregateCombination;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::AggregateCombination

=cut

__PACKAGE__->table("aggregate_combination");

=head1 ACCESSORS

=head2 aggregate_combination_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 aggregate_combination_formula

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "aggregate_combination_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "aggregate_combination_formula",
  { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("aggregate_combination_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-02-15 18:00:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tLyHmT6MCY8PuKiMUZPZng


# You can replace this text with custom content, and it will be preserved on regeneration
1;
