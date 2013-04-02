use utf8;
package AdministratorDB::Schema::Result::KanopyaAggregator;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::KanopyaAggregator

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

=head1 TABLE: C<kanopya_aggregator>

=cut

__PACKAGE__->table("kanopya_aggregator");

=head1 ACCESSORS

=head2 kanopya_aggregator_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 time_step

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 storage_duration

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "kanopya_aggregator_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "time_step",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "storage_duration",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</kanopya_aggregator_id>

=back

=cut

__PACKAGE__->set_primary_key("kanopya_aggregator_id");

=head1 RELATIONS

=head2 kanopya_aggregator

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "kanopya_aggregator",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "kanopya_aggregator_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2013-03-27 16:05:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZXj/xreedK8/f3Mfth07Lw

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "kanopya_aggregator_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
