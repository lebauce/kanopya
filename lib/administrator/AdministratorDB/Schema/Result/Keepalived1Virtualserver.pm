package AdministratorDB::Schema::Result::Keepalived1Virtualserver;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Keepalived1Virtualserver

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

=head2 virtualserver_ip

  data_type: 'char'
  is_nullable: 0
  size: 39

=head2 virtualserver_port

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 virtualserver_lbalgo

  data_type: 'enum'
  default_value: 'rr'
  extra: {list => ["rr","wrr","lc","wlc","sh","dh","lblc"]}
  is_nullable: 0

=head2 virtualserver_lbkind

  data_type: 'enum'
  default_value: 'NAT'
  extra: {list => ["NAT","DR","TUN"]}
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
  "virtualserver_ip",
  { data_type => "char", is_nullable => 0, size => 39 },
  "virtualserver_port",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "virtualserver_lbalgo",
  {
    data_type => "enum",
    default_value => "rr",
    extra => { list => ["rr", "wrr", "lc", "wlc", "sh", "dh", "lblc"] },
    is_nullable => 0,
  },
  "virtualserver_lbkind",
  {
    data_type => "enum",
    default_value => "NAT",
    extra => { list => ["NAT", "DR", "TUN"] },
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("virtualserver_id");

=head1 RELATIONS

=head2 keepalived1_realservers

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Keepalived1Realserver>

=cut

__PACKAGE__->has_many(
  "keepalived1_realservers",
  "AdministratorDB::Schema::Result::Keepalived1Realserver",
  { "foreign.virtualserver_id" => "self.virtualserver_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 keepalived

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Keepalived1>

=cut

__PACKAGE__->belongs_to(
  "keepalived",
  "AdministratorDB::Schema::Result::Keepalived1",
  { keepalived_id => "keepalived_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-26 17:01:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VHbRN3DgDD/rbgcujoF0zQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
