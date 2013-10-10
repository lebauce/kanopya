use utf8;
package AdministratorDB::Schema::Result::TimePeriod;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::TimePeriod

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

=head1 TABLE: C<time_period>

=cut

__PACKAGE__->table("time_period");

=head1 ACCESSORS

=head2 time_period_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 time_period_name

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 param_preset_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "time_period_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "time_period_name",
  { data_type => "char", is_nullable => 1, size => 255 },
  "param_preset_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</time_period_id>

=back

=cut

__PACKAGE__->set_primary_key("time_period_id");

=head1 RELATIONS

=head2 entity_time_periods

Type: has_many

Related object: L<AdministratorDB::Schema::Result::EntityTimePeriod>

=cut

__PACKAGE__->has_many(
  "entity_time_periods",
  "AdministratorDB::Schema::Result::EntityTimePeriod",
  { "foreign.time_period_id" => "self.time_period_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 param_preset

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ParamPreset>

=cut

__PACKAGE__->belongs_to(
  "param_preset",
  "AdministratorDB::Schema::Result::ParamPreset",
  { param_preset_id => "param_preset_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 time_period

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "time_period",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "time_period_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2013-04-08 04:12:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1nFyhTPpaICvTvzqh+rUmg

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "time_period_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
