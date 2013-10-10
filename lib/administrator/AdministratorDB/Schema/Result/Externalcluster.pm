use utf8;
package AdministratorDB::Schema::Result::Externalcluster;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Externalcluster

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

=head1 TABLE: C<externalcluster>

=cut

__PACKAGE__->table("externalcluster");

=head1 ACCESSORS

=head2 externalcluster_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 externalcluster_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 externalcluster_desc

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 externalcluster_state

  data_type: 'char'
  default_value: 'down:0'
  is_nullable: 0
  size: 32

=head2 externalcluster_prev_state

  data_type: 'char'
  is_nullable: 1
  size: 32

=cut

__PACKAGE__->add_columns(
  "externalcluster_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "externalcluster_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "externalcluster_desc",
  { data_type => "char", is_nullable => 1, size => 255 },
  "externalcluster_state",
  {
    data_type => "char",
    default_value => "down:0",
    is_nullable => 0,
    size => 32,
  },
  "externalcluster_prev_state",
  { data_type => "char", is_nullable => 1, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</externalcluster_id>

=back

=cut

__PACKAGE__->set_primary_key("externalcluster_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<externalcluster_name>

=over 4

=item * L</externalcluster_name>

=back

=cut

__PACKAGE__->add_unique_constraint("externalcluster_name", ["externalcluster_name"]);

=head1 RELATIONS

=head2 externalcluster

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "externalcluster",
  "AdministratorDB::Schema::Result::ServiceProvider",
  { service_provider_id => "externalcluster_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2013-01-30 18:11:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TrTkXA7wNHfTaBV0VNGUpw

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::ServiceProvider",
  { service_provider_id => "externalcluster_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
