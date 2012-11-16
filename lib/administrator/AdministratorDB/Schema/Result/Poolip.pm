use utf8;
package AdministratorDB::Schema::Result::Poolip;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Poolip

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

=head1 TABLE: C<poolip>

=cut

__PACKAGE__->table("poolip");

=head1 ACCESSORS

=head2 poolip_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 poolip_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 poolip_first_addr

  data_type: 'char'
  is_nullable: 0
  size: 15

=head2 poolip_size

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 network_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "poolip_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "poolip_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "poolip_first_addr",
  { data_type => "char", is_nullable => 0, size => 15 },
  "poolip_size",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "network_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</poolip_id>

=back

=cut

__PACKAGE__->set_primary_key("poolip_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<poolip_name>

=over 4

=item * L</poolip_name>

=back

=cut

__PACKAGE__->add_unique_constraint("poolip_name", ["poolip_name"]);

=head1 RELATIONS

=head2 ips

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Ip>

=cut

__PACKAGE__->has_many(
  "ips",
  "AdministratorDB::Schema::Result::Ip",
  { "foreign.poolip_id" => "self.poolip_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 netconf_poolips

Type: has_many

Related object: L<AdministratorDB::Schema::Result::NetconfPoolip>

=cut

__PACKAGE__->has_many(
  "netconf_poolips",
  "AdministratorDB::Schema::Result::NetconfPoolip",
  { "foreign.poolip_id" => "self.poolip_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 network

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Network>

=cut

__PACKAGE__->belongs_to(
  "network",
  "AdministratorDB::Schema::Result::Network",
  { network_id => "network_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 poolip

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "poolip",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "poolip_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 netconfs

Type: many_to_many

Composing rels: L</netconf_poolips> -> netconf

=cut

__PACKAGE__->many_to_many("netconfs", "netconf_poolips", "netconf");


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-11-15 15:42:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:l2wvGaFeIAJY3wtCmFFtFQ

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "poolip_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
