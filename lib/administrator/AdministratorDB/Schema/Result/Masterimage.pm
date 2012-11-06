use utf8;
package AdministratorDB::Schema::Result::Masterimage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Masterimage

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

=head1 TABLE: C<masterimage>

=cut

__PACKAGE__->table("masterimage");

=head1 ACCESSORS

=head2 masterimage_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 masterimage_name

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 masterimage_file

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 masterimage_desc

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 masterimage_os

  data_type: 'char'
  is_nullable: 1
  size: 64

=head2 masterimage_size

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "masterimage_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "masterimage_name",
  { data_type => "char", is_nullable => 0, size => 64 },
  "masterimage_file",
  { data_type => "char", is_nullable => 0, size => 255 },
  "masterimage_desc",
  { data_type => "char", is_nullable => 1, size => 255 },
  "masterimage_os",
  { data_type => "char", is_nullable => 1, size => 64 },
  "masterimage_size",
  { data_type => "bigint", extra => { unsigned => 1 }, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</masterimage_id>

=back

=cut

__PACKAGE__->set_primary_key("masterimage_id");

=head1 RELATIONS

=head2 clusters

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Cluster>

=cut

__PACKAGE__->has_many(
  "clusters",
  "AdministratorDB::Schema::Result::Cluster",
  { "foreign.masterimage_id" => "self.masterimage_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 component_types

Type: many_to_many

Composing rels: L</components_provided> -> component_type

=cut

__PACKAGE__->many_to_many("component_types", "components_provided", "component_type");

=head2 components_provided

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ComponentProvided>

=cut

__PACKAGE__->has_many(
  "components_provided",
  "AdministratorDB::Schema::Result::ComponentProvided",
  { "foreign.masterimage_id" => "self.masterimage_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 masterimage

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "masterimage",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "masterimage_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 component_types

Type: many_to_many

Composing rels: L</components_provided> -> component_type

=cut

__PACKAGE__->many_to_many("component_types", "components_provided", "component_type");


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-11-06 11:22:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VtJs72bW3BdEisL0uAagNw

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "masterimage_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
