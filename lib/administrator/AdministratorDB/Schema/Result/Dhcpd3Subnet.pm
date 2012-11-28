package AdministratorDB::Schema::Result::Dhcpd3Subnet;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Dhcpd3Subnet

=cut

__PACKAGE__->table("dhcpd3_subnet");

=head1 ACCESSORS

=head2 dhcpd3_subnet_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 dhcpd3_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 dhcpd3_subnet_net

  data_type: 'char'
  is_nullable: 0
  size: 40

=head2 dhcpd3_subnet_mask

  data_type: 'char'
  is_nullable: 0
  size: 40

=head2 dhcpd3_subnet_gateway

  data_type: 'char'
  default_value: '0.0.0.0'
  is_nullable: 0
  size: 40

=cut

__PACKAGE__->add_columns(
  "dhcpd3_subnet_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "dhcpd3_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "dhcpd3_subnet_net",
  { data_type => "char", is_nullable => 0, size => 40 },
  "dhcpd3_subnet_mask",
  { data_type => "char", is_nullable => 0, size => 40 },
  "dhcpd3_subnet_gateway",
  {
    data_type => "char",
    default_value => "0.0.0.0",
    is_nullable => 0,
    size => 40,
  },
);
__PACKAGE__->set_primary_key("dhcpd3_subnet_id");

=head1 RELATIONS

=head2 dhcpd3_hosts

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Dhcpd3Host>

=cut

__PACKAGE__->has_many(
  "dhcpd3_hosts",
  "AdministratorDB::Schema::Result::Dhcpd3Host",
  { "foreign.dhcpd3_subnet_id" => "self.dhcpd3_subnet_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 dhcpd3

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Dhcpd3>

=cut

__PACKAGE__->belongs_to(
  "dhcpd3",
  "AdministratorDB::Schema::Result::Dhcpd3",
  { dhcpd3_id => "dhcpd3_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-06-20 03:38:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FTfTf2ImvfgAGFehZwu4vw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
