package AdministratorDB::Schema::Result::VlanPoolip;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::VlanPoolip

=cut

__PACKAGE__->table("vlan_poolip");

=head1 ACCESSORS

=head2 vlan_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 poolip_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "vlan_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "poolip_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("vlan_id", "poolip_id");

=head1 RELATIONS

=head2 vlan

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Vlan>

=cut

__PACKAGE__->belongs_to(
  "vlan",
  "AdministratorDB::Schema::Result::Vlan",
  { vlan_id => "vlan_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 poolip

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Poolip>

=cut

__PACKAGE__->belongs_to(
  "poolip",
  "AdministratorDB::Schema::Result::Poolip",
  { poolip_id => "poolip_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-02-14 18:09:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CDQS6kNKeNfEKxuP7B9ybQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
