use utf8;
package AdministratorDB::Schema::Result::Keepalived1Virtualip;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Keepalived1Virtualip

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

=head1 TABLE: C<keepalived1_virtualip>

=cut

__PACKAGE__->table("keepalived1_virtualip");

=head1 ACCESSORS

=head2 virtualip_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 vrrpinstance_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 ip_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 interface_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "virtualip_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "vrrpinstance_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "ip_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "interface_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</virtualip_id>

=back

=cut

__PACKAGE__->set_primary_key("virtualip_id");

=head1 RELATIONS

=head2 interface

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Interface>

=cut

__PACKAGE__->belongs_to(
  "interface",
  "AdministratorDB::Schema::Result::Interface",
  { interface_id => "interface_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 ip

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Ip>

=cut

__PACKAGE__->belongs_to(
  "ip",
  "AdministratorDB::Schema::Result::Ip",
  { ip_id => "ip_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 vrrpinstance

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Keepalived1Vrrpinstance>

=cut

__PACKAGE__->belongs_to(
  "vrrpinstance",
  "AdministratorDB::Schema::Result::Keepalived1Vrrpinstance",
  { vrrpinstance_id => "vrrpinstance_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-03 17:32:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QTTapnmixt7uVnSWHFuTvg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
