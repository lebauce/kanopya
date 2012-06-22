use utf8;
package AdministratorDB::Schema::Result::VerifiedNoderule;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::VerifiedNoderule

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<verified_noderule>

=cut

__PACKAGE__->table("verified_noderule");

=head1 ACCESSORS

=head2 verified_noderule_externalnode_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 verified_noderule_nodemetric_rule_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 verified_noderule_state

  data_type: 'char'
  is_nullable: 0
  size: 8

=head2 workflow_def_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "verified_noderule_externalnode_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "verified_noderule_nodemetric_rule_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "verified_noderule_state",
  { data_type => "char", is_nullable => 0, size => 8 },
  "workflow_def_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</verified_noderule_externalnode_id>

=item * L</verified_noderule_nodemetric_rule_id>

=back

=cut

__PACKAGE__->set_primary_key(
  "verified_noderule_externalnode_id",
  "verified_noderule_nodemetric_rule_id",
);

=head1 RELATIONS

=head2 verified_noderule_externalnode

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Externalnode>

=cut

__PACKAGE__->belongs_to(
  "verified_noderule_externalnode",
  "AdministratorDB::Schema::Result::Externalnode",
  { externalnode_id => "verified_noderule_externalnode_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 verified_noderule_nodemetric_rule

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::NodemetricRule>

=cut

__PACKAGE__->belongs_to(
  "verified_noderule_nodemetric_rule",
  "AdministratorDB::Schema::Result::NodemetricRule",
  { nodemetric_rule_id => "verified_noderule_nodemetric_rule_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 workflow_def

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::WorkflowDef>

=cut

__PACKAGE__->belongs_to(
  "workflow_def",
  "AdministratorDB::Schema::Result::WorkflowDef",
  { workflow_def_id => "workflow_def_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-06-20 20:47:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BC53iY26XjFLreHuci44dA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
