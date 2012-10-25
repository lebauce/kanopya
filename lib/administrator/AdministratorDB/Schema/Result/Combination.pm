use utf8;
package AdministratorDB::Schema::Result::Combination;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Combination

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<combination>

=cut

__PACKAGE__->table("combination");

=head1 ACCESSORS

=head2 combination_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "combination_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</combination_id>

=back

=cut

__PACKAGE__->set_primary_key("combination_id");

=head1 RELATIONS

=head2 aggregate_combination

Type: might_have

Related object: L<AdministratorDB::Schema::Result::AggregateCombination>

=cut

__PACKAGE__->might_have(
  "aggregate_combination",
  "AdministratorDB::Schema::Result::AggregateCombination",
  { "foreign.aggregate_combination_id" => "self.combination_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nodemetric_combination

Type: might_have

Related object: L<AdministratorDB::Schema::Result::NodemetricCombination>

=cut

__PACKAGE__->might_have(
  "nodemetric_combination",
  "AdministratorDB::Schema::Result::NodemetricCombination",
  { "foreign.nodemetric_combination_id" => "self.combination_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-10-25 13:06:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XOc6cPTjLdox3LP2COQsew


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
