use utf8;
package AdministratorDB::Schema::Result::ClusterType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::ClusterType

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

=head1 TABLE: C<cluster_type>

=cut

__PACKAGE__->table("cluster_type");

=head1 ACCESSORS

=head2 cluster_type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "cluster_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</cluster_type_id>

=back

=cut

__PACKAGE__->set_primary_key("cluster_type_id");

=head1 RELATIONS

=head2 cluster_type

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ServiceProviderType>

=cut

__PACKAGE__->belongs_to(
  "cluster_type",
  "AdministratorDB::Schema::Result::ServiceProviderType",
  { service_provider_type_id => "cluster_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 masterimages

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Masterimage>

=cut

__PACKAGE__->has_many(
  "masterimages",
  "AdministratorDB::Schema::Result::Masterimage",
  { "foreign.masterimage_cluster_type_id" => "self.cluster_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2013-07-25 17:17:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OHtSInOwvK8vWk+PfDYhcQ

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::ServiceProviderType",
  { service_provider_type_id => "cluster_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
