use utf8;
package AdministratorDB::Schema::Result::Externalnode;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Externalnode

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<externalnode>

=cut

__PACKAGE__->table("externalnode");

=head1 ACCESSORS

=head2 externalnode_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 externalnode_hostname

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 service_provider_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 externalnode_state

  data_type: 'char'
  is_nullable: 1
  size: 32

=head2 externalnode_prev_state

  data_type: 'char'
  is_nullable: 1
  size: 32

=cut

__PACKAGE__->add_columns(
  "externalnode_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "externalnode_hostname",
  { data_type => "char", is_nullable => 0, size => 255 },
  "service_provider_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "externalnode_state",
  { data_type => "char", is_nullable => 1, size => 32 },
  "externalnode_prev_state",
  { data_type => "char", is_nullable => 1, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</externalnode_id>

=back

=cut

__PACKAGE__->set_primary_key("externalnode_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<externalnode_hostname>

=over 4

=item * L</externalnode_hostname>

=item * L</service_provider_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "externalnode_hostname",
  ["externalnode_hostname", "service_provider_id"],
);

=head1 RELATIONS

=head2 node

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Node>

=cut

__PACKAGE__->might_have(
  "node",
  "AdministratorDB::Schema::Result::Node",
  { "foreign.node_id" => "self.externalnode_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_provider

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "service_provider",
  "AdministratorDB::Schema::Result::ServiceProvider",
  { service_provider_id => "service_provider_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 verified_noderules

Type: has_many

Related object: L<AdministratorDB::Schema::Result::VerifiedNoderule>

=cut

__PACKAGE__->has_many(
  "verified_noderules",
  "AdministratorDB::Schema::Result::VerifiedNoderule",
  {
    "foreign.verified_noderule_externalnode_id" => "self.externalnode_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-06-20 13:13:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pDBmE9IiJMb/vwvUq1R0zg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
