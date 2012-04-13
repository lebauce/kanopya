package AdministratorDB::Schema::Result::Ip;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Ip

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
  is_nullable: 1

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
    is_nullable => 1,
  },
  "iface_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("ip_id");
__PACKAGE__->add_unique_constraint("ip_addr", ["ip_addr", "poolip_id"]);

=head1 RELATIONS

=head2 poolip

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Poolip>

=cut

__PACKAGE__->belongs_to(
  "poolip",
  "AdministratorDB::Schema::Result::Poolip",
  { poolip_id => "poolip_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 iface

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Iface>

=cut

__PACKAGE__->belongs_to(
  "iface",
  "AdministratorDB::Schema::Result::Iface",
  { iface_id => "iface_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-02-14 18:09:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:E4SZL9bhtshWp3oOCKsmXA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
