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
  "vlan_number",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("vlan_id");
__PACKAGE__->add_unique_constraint("vlan_number", ["vlan_number"]);

=head1 RELATIONS

=head2 vlan

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Network>

=cut

__PACKAGE__->belongs_to(
  "vlan",
  "AdministratorDB::Schema::Result::Network",
  { network_id => "vlan_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-04-17 14:30:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Q3JI5ZQon4EGbRWEDzWe3Q

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Network",
  { "foreign.network_id" => "self.vlan_id" },
  { cascade_copy => 0, cascade_delete => 1 }
);

1;
