package AdministratorDB::Schema::Result::VerifiedNoderule;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::VerifiedNoderule

=cut

__PACKAGE__->table("verified_noderule");

=head1 ACCESSORS

=head2 verified_rule_externalnode_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 verified_rule_nodemetric_rule_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "verified_rule_externalnode_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "verified_rule_nodemetric_rule_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key(
  "verified_rule_externalnode_id",
  "verified_rule_nodemetric_rule_id",
);

=head1 RELATIONS

=head2 verified_rule_nodemetric_rule

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::NodemetricRule>

=cut

__PACKAGE__->belongs_to(
  "verified_rule_nodemetric_rule",
  "AdministratorDB::Schema::Result::NodemetricRule",
  { nodemetric_rule_id => "verified_rule_nodemetric_rule_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 verified_rule_externalnode

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Externalnode>

=cut

__PACKAGE__->belongs_to(
  "verified_rule_externalnode",
  "AdministratorDB::Schema::Result::Externalnode",
  { externalnode_id => "verified_rule_externalnode_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-07 14:37:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AmXNf6cBvEv5M9aL088c7w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
