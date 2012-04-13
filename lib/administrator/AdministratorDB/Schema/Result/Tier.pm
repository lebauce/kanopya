package AdministratorDB::Schema::Result::Tier;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Tier

=cut

__PACKAGE__->table("tier");

=head1 ACCESSORS

=head2 tier_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 infrastructure_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 cluster_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 tier_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 tier_rank

  data_type: 'integer'
  is_nullable: 0

=head2 tier_data_src

  data_type: 'char'
  is_nullable: 0
  size: 128

=head2 tier_poststart_script

  data_type: 'char'
  is_nullable: 1
  size: 64

=cut

__PACKAGE__->add_columns(
  "tier_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "infrastructure_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "cluster_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "tier_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "tier_rank",
  { data_type => "integer", is_nullable => 0 },
  "tier_data_src",
  { data_type => "char", is_nullable => 0, size => 128 },
  "tier_poststart_script",
  { data_type => "char", is_nullable => 1, size => 64 },
);
__PACKAGE__->set_primary_key("tier_id");

=head1 RELATIONS

=head2 components

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->has_many(
  "components",
  "AdministratorDB::Schema::Result::Component",
  { "foreign.tier_id" => "self.tier_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ipv4_dmzzes

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Ipv4Dmz>

=cut

__PACKAGE__->has_many(
  "ipv4_dmzzes",
  "AdministratorDB::Schema::Result::Ipv4Dmz",
  { "foreign.tier_id" => "self.tier_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 tier

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "tier",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "tier_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 infrastructure

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Infrastructure>

=cut

__PACKAGE__->belongs_to(
  "infrastructure",
  "AdministratorDB::Schema::Result::Infrastructure",
  { infrastructure_id => "infrastructure_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 cluster

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Cluster>

=cut

__PACKAGE__->belongs_to(
  "cluster",
  "AdministratorDB::Schema::Result::Cluster",
  { cluster_id => "cluster_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-26 16:29:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:e7DAjLigcD68l6P6vJcXtg


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
    { "foreign.entity_id" => "self.tier_id" },
    { cascade_copy => 0, cascade_delete => 1 });

1;
