package AdministratorDB::Schema::Result::Vlan;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Vlan

=cut

__PACKAGE__->table("vlan");

=head1 ACCESSORS

=head2 vlan_id

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 vlan_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 vlan_desc

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 vlan_number

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "vlan_id",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "vlan_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "vlan_desc",
  { data_type => "char", is_nullable => 1, size => 255 },
  "vlan_number",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("vlan_id");
__PACKAGE__->add_unique_constraint("vlan_number", ["vlan_number"]);
__PACKAGE__->add_unique_constraint("vlan_name", ["vlan_name"]);

=head1 RELATIONS

=head2 interface_vlans

Type: has_many

Related object: L<AdministratorDB::Schema::Result::InterfaceVlan>

=cut

__PACKAGE__->has_many(
  "interface_vlans",
  "AdministratorDB::Schema::Result::InterfaceVlan",
  { "foreign.vlan_id" => "self.vlan_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vlan

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "vlan",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "vlan_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 vlan_poolips

Type: has_many

Related object: L<AdministratorDB::Schema::Result::VlanPoolip>

=cut

__PACKAGE__->has_many(
  "vlan_poolips",
  "AdministratorDB::Schema::Result::VlanPoolip",
  { "foreign.vlan_id" => "self.vlan_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-02-14 18:09:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:daNN6ZXuVrM1OS5z/xnIFQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
