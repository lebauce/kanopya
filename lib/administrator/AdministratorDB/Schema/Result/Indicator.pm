package AdministratorDB::Schema::Result::Indicator;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Indicator

=cut

__PACKAGE__->table("indicator");

=head1 ACCESSORS

=head2 indicator_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 indicator_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 indicator_oid

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 indicator_min

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 indicator_max

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 indicator_color

  data_type: 'char'
  is_nullable: 1
  size: 8

=head2 indicatorset_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "indicator_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "indicator_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "indicator_oid",
  { data_type => "char", is_nullable => 0, size => 64 },
  "indicator_min",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "indicator_max",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "indicator_color",
  { data_type => "char", is_nullable => 1, size => 8 },
  "indicatorset_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "indicator_unity",
  { data_type => "char", is_nullable => 0, size => 32 },
);
__PACKAGE__->set_primary_key("indicator_id");

=head1 RELATIONS

=head2 indicatorset

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Indicatorset>

=cut

__PACKAGE__->belongs_to(
  "indicatorset",
  "AdministratorDB::Schema::Result::Indicatorset",
  { indicatorset_id => "indicatorset_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-25 14:17:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BfEQXqwQ+FEZ+0W7M93PZw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
