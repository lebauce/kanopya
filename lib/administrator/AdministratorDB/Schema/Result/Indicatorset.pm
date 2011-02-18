package AdministratorDB::Schema::Result::Indicatorset;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Indicatorset

=cut

__PACKAGE__->table("indicatorset");

=head1 ACCESSORS

=head2 indicatorset_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 indicatorset_name

  data_type: 'char'
  is_nullable: 0
  size: 16

=head2 indicatorset_provider

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 indicatorset_type

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 indicatorset_component

  data_type: 'char'
  is_nullable: 1
  size: 32

=head2 indicatorset_max

  data_type: 'char'
  is_nullable: 1
  size: 128

=cut

__PACKAGE__->add_columns(
  "indicatorset_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "indicatorset_name",
  { data_type => "char", is_nullable => 0, size => 16 },
  "indicatorset_provider",
  { data_type => "char", is_nullable => 0, size => 32 },
  "indicatorset_type",
  { data_type => "char", is_nullable => 0, size => 32 },
  "indicatorset_component",
  { data_type => "char", is_nullable => 1, size => 32 },
  "indicatorset_max",
  { data_type => "char", is_nullable => 1, size => 128 },
);
__PACKAGE__->set_primary_key("indicatorset_id");

=head1 RELATIONS

=head2 collects

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Collect>

=cut

__PACKAGE__->has_many(
  "collects",
  "AdministratorDB::Schema::Result::Collect",
  { "foreign.indicatorset_id" => "self.indicatorset_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 graphs

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Graph>

=cut

__PACKAGE__->has_many(
  "graphs",
  "AdministratorDB::Schema::Result::Graph",
  { "foreign.indicatorset_id" => "self.indicatorset_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 indicators

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Indicator>

=cut

__PACKAGE__->has_many(
  "indicators",
  "AdministratorDB::Schema::Result::Indicator",
  { "foreign.indicatorset_id" => "self.indicatorset_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:S4n1QTRGvDWRtb3lbMjc8g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
