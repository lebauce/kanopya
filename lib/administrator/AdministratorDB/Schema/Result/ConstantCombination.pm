use utf8;
package AdministratorDB::Schema::Result::ConstantCombination;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::ConstantCombination

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<constant_combination>

=cut

__PACKAGE__->table("constant_combination");

=head1 ACCESSORS

=head2 constant_combination_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 value

  data_type: 'char'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "constant_combination_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "value",
  { data_type => "char", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</constant_combination_id>

=back

=cut

__PACKAGE__->set_primary_key("constant_combination_id");

# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-10-25 17:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tA6bz5caQRG3gqNUQPFw3w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
 __PACKAGE__->belongs_to(
   "parent",
     "AdministratorDB::Schema::Result::Combination",
         { "foreign.combination_id" => "self.constant_combination_id" },
             { cascade_copy => 0, cascade_delete => 1 }
 );
1;
