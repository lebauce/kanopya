package AdministratorDB::Schema::Result::Openldap1;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Openldap1

=cut

__PACKAGE__->table("openldap1");

=head1 ACCESSORS

=head2 openldap1_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 component_instance_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 openldap1_port

  data_type: 'integer'
  default_value: 389
  extra: {unsigned => 1}
  is_nullable: 0

=head2 openldap1_suffix

  data_type: 'char'
  default_value: 'dc=nodomain'
  is_nullable: 0
  size: 64

=head2 openldap1_directory

  data_type: 'char'
  default_value: '/var/lib/ldap'
  is_nullable: 0
  size: 64

=head2 openldap1_rootdn

  data_type: 'char'
  default_value: 'dc=admin,dc=nodomain'
  is_nullable: 0
  size: 64

=head2 openldap1_rootpw

  data_type: 'char'
  is_nullable: 1
  size: 64

=cut

__PACKAGE__->add_columns(
  "openldap1_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "component_instance_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "openldap1_port",
  {
    data_type => "integer",
    default_value => 389,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "openldap1_suffix",
  {
    data_type => "char",
    default_value => "dc=nodomain",
    is_nullable => 0,
    size => 64,
  },
  "openldap1_directory",
  {
    data_type => "char",
    default_value => "/var/lib/ldap",
    is_nullable => 0,
    size => 64,
  },
  "openldap1_rootdn",
  {
    data_type => "char",
    default_value => "dc=admin,dc=nodomain",
    is_nullable => 0,
    size => 64,
  },
  "openldap1_rootpw",
  { data_type => "char", is_nullable => 1, size => 64 },
);
__PACKAGE__->set_primary_key("openldap1_id");
__PACKAGE__->add_unique_constraint("fk_openldap1_1", ["component_instance_id"]);

=head1 RELATIONS

=head2 component_instance

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ComponentInstance>

=cut

__PACKAGE__->belongs_to(
  "component_instance",
  "AdministratorDB::Schema::Result::ComponentInstance",
  { component_instance_id => "component_instance_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-09-07 18:31:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qUmY+CaXhUTBHsdezYeTMA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
