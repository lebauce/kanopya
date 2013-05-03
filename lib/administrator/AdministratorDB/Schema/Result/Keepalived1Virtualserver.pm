use utf8;
package AdministratorDB::Schema::Result::Keepalived1Virtualserver;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Keepalived1Virtualserver

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

=head1 TABLE: C<keepalived1_virtualserver>

=cut

__PACKAGE__->table("keepalived1_virtualserver");

=head1 ACCESSORS

=head2 virtualserver_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 keepalived_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 virtualserver_name

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 virtualserver_ip

  data_type: 'char'
  is_nullable: 0
  size: 17

=head2 virtualserver_port

  data_type: 'integer'
  is_nullable: 0

=head2 virtualserver_protocol

  data_type: 'enum'
  extra: {list => ["TCP","UDP"]}
  is_nullable: 0

=head2 virtualserver_persistence_timeout

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 virtualserver_lbalgo

  data_type: 'enum'
  default_value: 'rr'
  extra: {list => ["rr","wrr","lc","wlc","lblc","lblcr","dh","sh","sed","nq"]}
  is_nullable: 0

=head2 virtualserver_lbkind

  data_type: 'enum'
  default_value: 'NAT'
  extra: {list => ["NAT","DR","TUN"]}
  is_nullable: 0

=head2 component_id

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
  "virtualserver_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "keepalived_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "virtualserver_name",
  { data_type => "char", is_nullable => 0, size => 64 },
  "virtualserver_ip",
  { data_type => "char", is_nullable => 0, size => 17 },
  "virtualserver_port",
  { data_type => "integer", is_nullable => 0 },
  "virtualserver_protocol",
  {
    data_type => "enum",
    extra => { list => ["TCP", "UDP"] },
    is_nullable => 0,
  },
  "virtualserver_persistence_timeout",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "virtualserver_lbalgo",
  {
    data_type => "enum",
    default_value => "rr",
    extra => {
      list => ["rr", "wrr", "lc", "wlc", "lblc", "lblcr", "dh", "sh", "sed", "nq"],
    },
    is_nullable => 0,
  },
  "virtualserver_lbkind",
  {
    data_type => "enum",
    default_value => "NAT",
    extra => { list => ["NAT", "DR", "TUN"] },
    is_nullable => 0,
  },
  "component_id",
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

=item * L</virtualserver_id>

=back

=cut

__PACKAGE__->set_primary_key("virtualserver_id");

=head1 RELATIONS

=head2 component

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "component",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "component_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

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

=head2 keepalived

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Keepalived1>

=cut

__PACKAGE__->belongs_to(
  "keepalived",
  "AdministratorDB::Schema::Result::Keepalived1",
  { keepalived_id => "keepalived_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-03 13:44:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:l0h7eUXQrwWmtO3cCEhYLg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
