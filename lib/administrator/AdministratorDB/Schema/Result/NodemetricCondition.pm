package AdministratorDB::Schema::Result::NodemetricCondition;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::NodemetricCondition

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
  is_foreign_key: 1
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
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
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
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 nodemetric_condition_service_provider

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "nodemetric_condition_service_provider",
  "AdministratorDB::Schema::Result::ServiceProvider",
  {
    service_provider_id => "nodemetric_condition_service_provider_id",
  },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-06-13 11:27:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:37t2YDDS3CuoZFoZArY3Hw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
