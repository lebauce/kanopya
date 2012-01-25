package AdministratorDB::Schema::Result::Ipv4Internal;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Ipv4Internal

=cut

__PACKAGE__->table("ipv4_internal");

=head1 ACCESSORS

=head2 ipv4_internal_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 ipv4_internal_address

  data_type: 'char'
  is_nullable: 0
  size: 15

=head2 ipv4_internal_mask

  data_type: 'char'
  is_nullable: 0
  size: 15

=head2 ipv4_internal_default_gw

  data_type: 'char'
  is_nullable: 1
  size: 15

=cut

__PACKAGE__->add_columns(
  "ipv4_internal_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "ipv4_internal_address",
  { data_type => "char", is_nullable => 0, size => 15 },
  "ipv4_internal_mask",
  { data_type => "char", is_nullable => 0, size => 15 },
  "ipv4_internal_default_gw",
  { data_type => "char", is_nullable => 1, size => 15 },
);
__PACKAGE__->set_primary_key("ipv4_internal_id");
__PACKAGE__->add_unique_constraint("ipv4_internal_address_UNIQUE", ["ipv4_internal_address"]);

=head1 RELATIONS

=head2 hosts

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Host>

=cut

__PACKAGE__->has_many(
  "hosts",
  "AdministratorDB::Schema::Result::Host",
  { "foreign.host_ipv4_internal_id" => "self.ipv4_internal_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 powersupplycards

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Powersupplycard>

=cut

__PACKAGE__->has_many(
  "powersupplycards",
  "AdministratorDB::Schema::Result::Powersupplycard",
  { "foreign.ipv4_internal_id" => "self.ipv4_internal_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-25 14:17:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:e2X/k/O4TzqQXOtOtcGPlA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
