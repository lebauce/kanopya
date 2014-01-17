use utf8;
package Kanopya::Schema::Result::Ip;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Ip

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

=head1 TABLE: C<ip>

=cut

__PACKAGE__->table("ip");

=head1 ACCESSORS

=head2 ip_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 ip_addr

  data_type: 'char'
  is_nullable: 0
  size: 15

=head2 poolip_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 iface_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "ip_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "ip_addr",
  { data_type => "char", is_nullable => 0, size => 15 },
  "poolip_id",
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
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</ip_id>

=back

=cut

__PACKAGE__->set_primary_key("ip_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<ip_addr>

=over 4

=item * L</ip_addr>

=item * L</poolip_id>

=back

=cut

__PACKAGE__->add_unique_constraint("ip_addr", ["ip_addr", "poolip_id"]);

=head1 RELATIONS

=head2 iface

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Iface>

=cut

__PACKAGE__->belongs_to(
  "iface",
  "Kanopya::Schema::Result::Iface",
  { iface_id => "iface_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 keepalived1_vrrpinstances

Type: has_many

Related object: L<Kanopya::Schema::Result::Keepalived1Vrrpinstance>

=cut

__PACKAGE__->has_many(
  "keepalived1_vrrpinstances",
  "Kanopya::Schema::Result::Keepalived1Vrrpinstance",
  { "foreign.virtualip_id" => "self.ip_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 poolip

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Poolip>

=cut

__PACKAGE__->belongs_to(
  "poolip",
  "Kanopya::Schema::Result::Poolip",
  { poolip_id => "poolip_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:60iOSFSbCWEMZcv7jm3oDA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
