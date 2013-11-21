use utf8;
package Kanopya::Schema::Result::Rulecondition;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Rulecondition

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<DBIx::Class::IntrospectableM2M>

=cut

use base 'DBIx::Class::IntrospectableM2M';

=head1 LEFT BASE CLASSES

=over 4

=item * L<DBIx::Class::Core>

=back

=cut

use base qw/DBIx::Class::Core/;

=head1 TABLE: C<rulecondition>

=cut

__PACKAGE__->table("rulecondition");

=head1 ACCESSORS

=head2 rulecondition_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 rulecondition_var

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 rulecondition_time_laps

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 rulecondition_consolidation_func

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 rulecondition_transformation_func

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 rulecondition_operator

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 rulecondition_value

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 rule_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "rulecondition_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "rulecondition_var",
  { data_type => "char", is_nullable => 0, size => 64 },
  "rulecondition_time_laps",
  { data_type => "char", is_nullable => 0, size => 32 },
  "rulecondition_consolidation_func",
  { data_type => "char", is_nullable => 0, size => 32 },
  "rulecondition_transformation_func",
  { data_type => "char", is_nullable => 0, size => 32 },
  "rulecondition_operator",
  { data_type => "char", is_nullable => 0, size => 32 },
  "rulecondition_value",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "rule_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</rulecondition_id>

=back

=cut

__PACKAGE__->set_primary_key("rulecondition_id");

=head1 RELATIONS

=head2 rule

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Rule>

=cut

__PACKAGE__->belongs_to(
  "rule",
  "Kanopya::Schema::Result::Rule",
  { rule_id => "rule_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mPrNLciLmB5cWbxL1SPbjQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
