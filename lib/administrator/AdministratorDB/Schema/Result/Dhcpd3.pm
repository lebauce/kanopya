package AdministratorDB::Schema::Result::Dhcpd3;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Dhcpd3

=cut

__PACKAGE__->table("dhcpd3");

=head1 ACCESSORS

=head2 dhcpd3_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 component_instance_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 dhcpd3_domain_name

  data_type: 'char'
  is_nullable: 1
  size: 128

=head2 dhcpd3_domain_server

  data_type: 'char'
  is_nullable: 1
  size: 128

=head2 dhcpd3_servername

  data_type: 'char'
  is_nullable: 1
  size: 128

=cut

__PACKAGE__->add_columns(
  "dhcpd3_id",
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
  "dhcpd3_domain_name",
  { data_type => "char", is_nullable => 1, size => 128 },
  "dhcpd3_domain_server",
  { data_type => "char", is_nullable => 1, size => 128 },
  "dhcpd3_servername",
  { data_type => "char", is_nullable => 1, size => 128 },
);
__PACKAGE__->set_primary_key("dhcpd3_id");

=head1 RELATIONS

=head2 component_instance

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ComponentInstance>

=cut

__PACKAGE__->belongs_to(
  "component_instance",
  "AdministratorDB::Schema::Result::ComponentInstance",
  { component_instance_id => "component_instance_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 dhcpd3_subnets

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Dhcpd3Subnet>

=cut

__PACKAGE__->has_many(
  "dhcpd3_subnets",
  "AdministratorDB::Schema::Result::Dhcpd3Subnet",
  { "foreign.dhcpd3_id" => "self.dhcpd3_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oRv5iaLf/j5JcAsY7z52zg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
