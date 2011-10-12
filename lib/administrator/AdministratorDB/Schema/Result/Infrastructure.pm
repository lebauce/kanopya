package AdministratorDB::Schema::Result::Infrastructure;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Infrastructure

=cut

__PACKAGE__->table("infrastructure");

=head1 ACCESSORS

=head2 infrastructure_reference

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 infrastructure_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 infrastructure_min_node

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 infrastructure_max_node

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 infrastructure_domainname

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 infrastructure_nameserver

  data_type: 'char'
  is_nullable: 0
  size: 15

=head2 infrastructure_tier_number

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "infrastructure_reference",
  { data_type => "char", is_nullable => 0, size => 64 },
  "infrastructure_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "infrastructure_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "infrastructure_version",
  { data_type => "char", is_nullable => 0, size => 32 },
  "infrastructure_min_node",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "infrastructure_max_node",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "infrastructure_domainname",
  { data_type => "char", is_nullable => 0, size => 64 },
  "infrastructure_nameserver",
  { data_type => "char", is_nullable => 0, size => 15 },
  "infrastructure_tier_number",
  { data_type => "integer", is_nullable => 1 },
  "infrastructure_state",
  { data_type => "char", default_value => "down", is_nullable => 0, size => 32 },
  "infrastructure_prev_state",
  { data_type => "char", is_nullable => 1, size => 32 },
  "infrastructure_desc",
  { data_type => "char", is_nullable => 1, size => 255 },
  "infrastructure_priority",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("infrastructure_id");

=head1 RELATIONS

=head2 ipv4_publics

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Ipv4Public>

=cut

__PACKAGE__->has_many(
  "ipv4_publics",
  "AdministratorDB::Schema::Result::Ipv4Public",
  { "foreign.infrastructure_id" => "self.infrastructure_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 tiers

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Tier>

=cut

__PACKAGE__->has_many(
  "tiers",
  "AdministratorDB::Schema::Result::Tier",
  { "foreign.infrastructure_id" => "self.infrastructure_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-10-01 12:16:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dKBdqWDMwJDr3bor0Y5p6Q


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::Result::InfrastructureEntity",
    { "foreign.infrastructure_id" => "self.infrastructure_id" },
    { cascade_copy => 0, cascade_delete => 0 });

1;
