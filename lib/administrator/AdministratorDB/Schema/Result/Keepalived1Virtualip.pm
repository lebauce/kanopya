package AdministratorDB::Schema::Result::Keepalived1Virtualip;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::IntrospectableM2M';

use base qw/DBIx::Class::Core/;

=head1 NAME

AdministratorDB::Schema::Result::Keepalived1Virtualip

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
__PACKAGE__->set_primary_key("virtualip_id");

=head1 RELATIONS

=head2 vrrpinstance

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Keepalived1Vrrpinstance>

=cut

__PACKAGE__->belongs_to(
  "vrrpinstance",
  "AdministratorDB::Schema::Result::Keepalived1Vrrpinstance",
  { vrrpinstance_id => "vrrpinstance_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 ip

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Ip>

=cut

__PACKAGE__->belongs_to(
  "ip",
  "AdministratorDB::Schema::Result::Ip",
  { ip_id => "ip_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 interface

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Interface>

=cut

__PACKAGE__->belongs_to(
  "interface",
  "AdministratorDB::Schema::Result::Interface",
  { interface_id => "interface_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-05-30 10:47:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LqS9ioD26XedcqyylP0swQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
