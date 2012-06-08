use utf8;
package AdministratorDB::Schema::Result::NodemetricCondition;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::NodemetricCondition

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<nodemetric_condition>

=cut

__PACKAGE__->table("nodemetric_condition");

=head1 ACCESSORS

=head2 nodemetric_condition_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 nodemetric_condition_label

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 nodemetric_condition_service_provider_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 nodemetric_condition_combination_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 nodemetric_condition_comparator

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 nodemetric_condition_threshold

  data_type: 'double precision'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "nodemetric_condition_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "nodemetric_condition_label",
  { data_type => "char", is_nullable => 1, size => 255 },
  "nodemetric_condition_service_provider_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "nodemetric_condition_combination_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "nodemetric_condition_comparator",
  { data_type => "char", is_nullable => 0, size => 32 },
  "nodemetric_condition_threshold",
  { data_type => "double precision", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</nodemetric_condition_id>

=back

=cut

__PACKAGE__->set_primary_key("nodemetric_condition_id");

=head1 RELATIONS

=head2 nodemetric_condition_combination

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::NodemetricCombination>

=cut

__PACKAGE__->belongs_to(
  "nodemetric_condition_combination",
  "AdministratorDB::Schema::Result::NodemetricCombination",
  {
    nodemetric_combination_id => "nodemetric_condition_combination_id",
  },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-06-07 17:15:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dMXtWoAQOZdMkgiAryhKQw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
