package AdministratorDB::Schema::Result::Poolip;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Poolip

=cut

__PACKAGE__->table("poolip");

=head1 ACCESSORS

=head2 poolip_id

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 poolip_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 poolip_addr

  data_type: 'char'
  is_nullable: 0
  size: 15

=head2 poolip_mask

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 poolip_netmask

  data_type: 'char'
  is_nullable: 0
  size: 15

=head2 poolip_gateway

  data_type: 'char'
  is_nullable: 0
  size: 15

=cut

__PACKAGE__->add_columns(
  "poolip_id",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "poolip_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "poolip_addr",
  { data_type => "char", is_nullable => 0, size => 15 },
  "poolip_mask",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "poolip_netmask",
  { data_type => "char", is_nullable => 0, size => 15 },
  "poolip_gateway",
  { data_type => "char", is_nullable => 0, size => 15 },
);
__PACKAGE__->set_primary_key("poolip_id");
__PACKAGE__->add_unique_constraint("poolip_name", ["poolip_name"]);
__PACKAGE__->add_unique_constraint("poolip_addr", ["poolip_addr", "poolip_mask"]);

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

=head2 network_poolips

Type: has_many

Related object: L<AdministratorDB::Schema::Result::NetworkPoolip>

=cut

__PACKAGE__->has_many(
  "network_poolips",
  "AdministratorDB::Schema::Result::NetworkPoolip",
  { "foreign.poolip_id" => "self.poolip_id" },
  { cascade_copy => 0, cascade_delete => 0 },
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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-04-24 11:28:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Jw15TWAOHfplOvN9E8XPrg

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
  { "foreign.entity_id" => "self.poolip_id" },
  { cascade_copy => 0, cascade_delete => 1 }
);

1;
