package AdministratorDB::Schema::Result::InterfaceRole;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::InterfaceRole

=cut

__PACKAGE__->table("interface_role");

=head1 ACCESSORS

=head2 interface_role_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_foreign_key: 1
  is_nullable: 0

=head2 interface_role_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "interface_role_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "interface_role_name",
  { data_type => "char", is_nullable => 0, size => 32 },
);
__PACKAGE__->set_primary_key("interface_role_id");
__PACKAGE__->add_unique_constraint("interface_role_name", ["interface_role_name"]);

=head1 RELATIONS

=head2 interfaces

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Interface>

=cut

__PACKAGE__->has_many(
  "interfaces",
  "AdministratorDB::Schema::Result::Interface",
  { "foreign.interface_role_id" => "self.interface_role_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 interface_role

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "interface_role",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "interface_role_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-04-18 17:24:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2pKf+K2b3IK6MQwvoMqjOQ

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
  { "foreign.entity_id" => "self.interface_role_id" },
  { cascade_copy => 0, cascade_delete => 1 }
);

1;
