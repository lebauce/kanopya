use utf8;
package AdministratorDB::Schema::Result::Kanopyacollector1;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Kanopyacollector1

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<kanopyacollector1>

=cut

__PACKAGE__->table("kanopyacollector1");

=head1 ACCESSORS

=head2 kanopya_collector1_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 collect_frequency

  data_type: 'integer'
  default_value: 3600
  extra: {unsigned => 1}
  is_nullable: 0

=head2 storage_time

  data_type: 'integer'
  default_value: 86400
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "kanopya_collector1_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "collect_frequency",
  {
    data_type => "integer",
    default_value => 3600,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "storage_time",
  {
    data_type => "integer",
    default_value => 86400,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
);

__PACKAGE__->set_primary_key("kanopya_collector1_id");

=head1 PRIMARY KEY

=over 4

=item * L</kanopya_collector1_id>

=back

=cut

__PACKAGE__->set_primary_key("kanopya_collector1_id");

=head1 RELATIONS

=head2 kanopyacollector1

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "kanopyacollector1",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "kanopya_collector1_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2012-04-26 12:51:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NSR6VHs5eek4q6V1oVqvrQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Component",
    { "foreign.component_id" => "self.kanopya_collector1_id" },
    { cascade_copy => 0, cascade_delete => 1 }
);


1;
