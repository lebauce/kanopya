package AdministratorDB::Schema::Result::Ipv4Dmz;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Ipv4Dmz

=cut

__PACKAGE__->table("ipv4_dmz");

=head1 ACCESSORS

=head2 ipv4_dmz_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 ipv4_dmz_address

  data_type: 'char'
  is_nullable: 0
  size: 15

=head2 ipv4_dmz_mask

  data_type: 'char'
  is_nullable: 0
  size: 15

=head2 tier_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "ipv4_dmz_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "ipv4_dmz_address",
  { data_type => "char", is_nullable => 0, size => 15 },
  "ipv4_dmz_mask",
  { data_type => "char", is_nullable => 0, size => 15 },
  "tier_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("ipv4_dmz_id");
__PACKAGE__->add_unique_constraint("ipv4_dmz_address_UNIQUE", ["ipv4_dmz_address"]);

=head1 RELATIONS

=head2 tier

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Tier>

=cut

__PACKAGE__->belongs_to(
  "tier",
  "AdministratorDB::Schema::Result::Tier",
  { tier_id => "tier_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-10-01 12:16:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xyJOFXgmpYrc4mBNW5I67Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
