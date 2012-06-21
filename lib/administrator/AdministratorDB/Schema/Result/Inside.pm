use utf8;
package AdministratorDB::Schema::Result::Inside;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Inside

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<inside>

=cut

__PACKAGE__->table("inside");

=head1 ACCESSORS

=head2 inside_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "inside_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</inside_id>

=back

=cut

__PACKAGE__->set_primary_key("inside_id");

=head1 RELATIONS

=head2 cluster

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Cluster>

=cut

__PACKAGE__->might_have(
  "cluster",
  "AdministratorDB::Schema::Result::Cluster",
  { "foreign.cluster_id" => "self.inside_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 components

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->has_many(
  "components",
  "AdministratorDB::Schema::Result::Component",
  { "foreign.service_provider_id" => "self.inside_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 inside

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "inside",
  "AdministratorDB::Schema::Result::ServiceProvider",
  { service_provider_id => "inside_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 nodes

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Node>

=cut

__PACKAGE__->has_many(
  "nodes",
  "AdministratorDB::Schema::Result::Node",
  { "foreign.inside_id" => "self.inside_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 server

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Server>

=cut

__PACKAGE__->might_have(
  "server",
  "AdministratorDB::Schema::Result::Server",
  { "foreign.server_id" => "self.inside_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-06-20 15:42:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Epzvb3thEwm7O4sNdfCtrQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::ServiceProvider",
  { "foreign.service_provider_id" => "self.inside_id" },
  { cascade_copy => 0, cascade_delete => 1 });


1;
