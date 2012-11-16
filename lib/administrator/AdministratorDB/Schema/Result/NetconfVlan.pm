use utf8;
package AdministratorDB::Schema::Result::NetconfVlan;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::NetconfVlan

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

=head1 TABLE: C<netconf_vlan>

=cut

__PACKAGE__->table("netconf_vlan");

=head1 ACCESSORS

=head2 netconf_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 vlan_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "netconf_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "vlan_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</netconf_id>

=item * L</vlan_id>

=back

=cut

__PACKAGE__->set_primary_key("netconf_id", "vlan_id");

=head1 RELATIONS

=head2 netconf

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Netconf>

=cut

__PACKAGE__->belongs_to(
  "netconf",
  "AdministratorDB::Schema::Result::Netconf",
  { netconf_id => "netconf_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 vlan

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Vlan>

=cut

__PACKAGE__->belongs_to(
  "vlan",
  "AdministratorDB::Schema::Result::Vlan",
  { vlan_id => "vlan_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-11-15 15:42:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fpMsQBpnDBIni/1mvkglag


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
