use utf8;
package AdministratorDB::Schema::Result::NetconfIface;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::NetconfIface

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

=head1 TABLE: C<netconf_iface>

=cut

__PACKAGE__->table("netconf_iface");

=head1 ACCESSORS

=head2 netconf_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 iface_id

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
  "iface_id",
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

=item * L</iface_id>

=back

=cut

__PACKAGE__->set_primary_key("netconf_id", "iface_id");

=head1 RELATIONS

=head2 iface

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Iface>

=cut

__PACKAGE__->belongs_to(
  "iface",
  "AdministratorDB::Schema::Result::Iface",
  { iface_id => "iface_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

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


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-11-15 15:42:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4Mf9y+F/iGm1+eim3iVUMQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
