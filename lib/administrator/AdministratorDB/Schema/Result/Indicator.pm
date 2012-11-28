use utf8;
package AdministratorDB::Schema::Result::Indicator;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Indicator

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<indicator>

=cut

__PACKAGE__->table("indicator");

=head1 ACCESSORS

=head2 indicator_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 indicator_label

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 indicator_name

  data_type: 'char'
  is_nullable: 0
  size: 64

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

=head2 indicator_unit

  data_type: 'char'
  is_nullable: 1
  size: 32

=head2 service_provider_id

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
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "indicator_label",
  { data_type => "char", is_nullable => 0, size => 64 },
  "indicator_name",
  { data_type => "char", is_nullable => 0, size => 64 },
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
  "indicator_unit",
  { data_type => "char", is_nullable => 1, size => 32 },
  "service_provider_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</indicator_id>

=back

=cut

__PACKAGE__->set_primary_key("indicator_id");

=head1 RELATIONS

=head2 collector_indicators

Type: has_many

Related object: L<AdministratorDB::Schema::Result::CollectorIndicator>

=cut

__PACKAGE__->has_many(
  "collector_indicators",
  "AdministratorDB::Schema::Result::CollectorIndicator",
  { "foreign.indicator_id" => "self.indicator_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 indicator

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "indicator",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "indicator_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

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

=head2 service_provider

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "service_provider",
  "AdministratorDB::Schema::Result::ServiceProvider",
  { service_provider_id => "service_provider_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-10-31 16:06:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zSI/9T4gg7ZutpSppMEUsA

 __PACKAGE__->belongs_to(
   "parent",
     "AdministratorDB::Schema::Result::Entity",
         { "foreign.entity_id" => "self.indicator_id" },
             { cascade_copy => 0, cascade_delete => 1 }
 );


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
