use utf8;
package AdministratorDB::Schema::Result::CollectorIndicator;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::CollectorIndicator

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<collector_indicator>

=cut

__PACKAGE__->table("collector_indicator");

=head1 ACCESSORS

=head2 collector_indicator_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 indicator_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 collector_manager_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "collector_indicator_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "indicator_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "collector_manager_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</collector_indicator_id>

=back

=cut

__PACKAGE__->set_primary_key("collector_indicator_id");

=head1 RELATIONS

=head2 clustermetrics

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Clustermetric>

=cut

__PACKAGE__->has_many(
  "clustermetrics",
  "AdministratorDB::Schema::Result::Clustermetric",
  {
    "foreign.clustermetric_indicator_id" => "self.collector_indicator_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 collector_indicator

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "collector_indicator",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "collector_indicator_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 collector_manager

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "collector_manager",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "collector_manager_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 indicator

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Indicator>

=cut

__PACKAGE__->belongs_to(
  "indicator",
  "AdministratorDB::Schema::Result::Indicator",
  { indicator_id => "indicator_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-10-31 16:06:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KAh8UC087CsY5P7QZupIHg

 __PACKAGE__->belongs_to(
   "parent",
     "AdministratorDB::Schema::Result::Entity",
         { "foreign.entity_id" => "self.collector_indicator_id" },
             { cascade_copy => 0, cascade_delete => 1 }
 );


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
