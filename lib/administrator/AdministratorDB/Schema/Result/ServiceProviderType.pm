use utf8;
package AdministratorDB::Schema::Result::ServiceProviderType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::ServiceProviderType

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

=head1 TABLE: C<service_provider_type>

=cut

__PACKAGE__->table("service_provider_type");

=head1 ACCESSORS

=head2 service_provider_type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 service_provider_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "service_provider_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "service_provider_name",
  { data_type => "char", is_nullable => 0, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</service_provider_type_id>

=back

=cut

__PACKAGE__->set_primary_key("service_provider_type_id");

=head1 RELATIONS

=head2 cluster_type

Type: might_have

Related object: L<AdministratorDB::Schema::Result::ClusterType>

=cut

__PACKAGE__->might_have(
  "cluster_type",
  "AdministratorDB::Schema::Result::ClusterType",
  { "foreign.cluster_type_id" => "self.service_provider_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_provider_type

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ClassType>

=cut

__PACKAGE__->belongs_to(
  "service_provider_type",
  "AdministratorDB::Schema::Result::ClassType",
  { class_type_id => "service_provider_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 service_provider_type_component_types

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ServiceProviderTypeComponentType>

=cut

__PACKAGE__->has_many(
  "service_provider_type_component_types",
  "AdministratorDB::Schema::Result::ServiceProviderTypeComponentType",
  {
    "foreign.service_provider_type_id" => "self.service_provider_type_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_providers

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->has_many(
  "service_providers",
  "AdministratorDB::Schema::Result::ServiceProvider",
  {
    "foreign.service_provider_type_id" => "self.service_provider_type_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 component_types

Type: many_to_many

Composing rels: L</service_provider_type_component_types> -> component_type

=cut

__PACKAGE__->many_to_many(
  "component_types",
  "service_provider_type_component_types",
  "component_type",
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2013-07-25 14:35:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Vy7X0ZuoTXO9kMuq1eQdtQ

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::ClassType",
  { class_type_id => "service_provider_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
