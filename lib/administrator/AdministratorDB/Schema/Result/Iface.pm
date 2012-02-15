package AdministratorDB::Schema::Result::Iface;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Iface

=cut

__PACKAGE__->table("iface");

=head1 ACCESSORS

=head2 iface_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 iface_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 iface_mac_addr

  data_type: 'char'
  is_nullable: 0
  size: 18

=head2 iface_pxe

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 host_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "iface_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "iface_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "iface_mac_addr",
  { data_type => "char", is_nullable => 0, size => 18 },
  "iface_pxe",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "host_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("iface_id");
__PACKAGE__->add_unique_constraint("iface_name", ["iface_name", "host_id"]);
__PACKAGE__->add_unique_constraint("iface_mac_addr", ["iface_mac_addr"]);

=head1 RELATIONS

=head2 host

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Host>

=cut

__PACKAGE__->belongs_to(
  "host",
  "AdministratorDB::Schema::Result::Host",
  { host_id => "host_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 ips

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Ip>

=cut

__PACKAGE__->has_many(
  "ips",
  "AdministratorDB::Schema::Result::Ip",
  { "foreign.iface_id" => "self.iface_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-02-14 18:09:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wrvgk0iPLsJ0QBTWwXs0lg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
