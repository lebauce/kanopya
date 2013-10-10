use utf8;
package AdministratorDB::Schema::Result::Kanopyacollector1;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Kanopyacollector1

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

=head1 TABLE: C<kanopyacollector1>

=cut

__PACKAGE__->table("kanopyacollector1");

=head1 ACCESSORS

=head2 kanopyacollector1_id

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

=head2 rrd_base_directory

  data_type: 'char'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "kanopyacollector1_id",
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
  "rrd_base_directory",
  { data_type => "char", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</kanopyacollector1_id>

=back

=cut

__PACKAGE__->set_primary_key("kanopyacollector1_id");

=head1 RELATIONS

=head2 kanopyacollector1

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "kanopyacollector1",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "kanopyacollector1_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2013-03-27 17:16:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SoHaidpcLKxqk0v5G9rMpA

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "kanopyacollector1_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
