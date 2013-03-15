package AdministratorDB::Schema::Result::NodemetricRule;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::NodemetricRule

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<DBIx::Class::IntrospectableM2M>

=cut

use base 'DBIx::Class::IntrospectableM2M';

=head1 LEFT BASE CLASSES

=over 4

=item * L<DBIx::Class::Core>

=back

=cut

use base qw/DBIx::Class::Core/;

=head1 TABLE: C<nodemetric_rule>

=cut

__PACKAGE__->table("nodemetric_rule");

=head1 ACCESSORS

=head2 nodemetric_rule_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "nodemetric_rule_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</nodemetric_rule_id>

=back

=cut

__PACKAGE__->set_primary_key("nodemetric_rule_id");

=head1 RELATIONS

=head2 nodemetric_rule

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Rule>

=cut

__PACKAGE__->belongs_to(
  "nodemetric_rule",
  "AdministratorDB::Schema::Result::Rule",
  { rule_id => "nodemetric_rule_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 verified_noderules

Type: has_many

Related object: L<AdministratorDB::Schema::Result::VerifiedNoderule>

=cut

__PACKAGE__->has_many(
  "verified_noderules",
  "AdministratorDB::Schema::Result::VerifiedNoderule",
  {
    "foreign.verified_noderule_nodemetric_rule_id" => "self.nodemetric_rule_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workflow_noderules

Type: has_many

Related object: L<AdministratorDB::Schema::Result::WorkflowNoderule>

=cut

__PACKAGE__->has_many(
  "workflow_noderules",
  "AdministratorDB::Schema::Result::WorkflowNoderule",
  { "foreign.nodemetric_rule_id" => "self.nodemetric_rule_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-06-15 11:21:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Q+Ff8UOs9tqSBMYFyVj4Yw

 __PACKAGE__->belongs_to(
   "parent",
     "AdministratorDB::Schema::Result::Rule",
         { "foreign.rule_id" => "self.nodemetric_rule_id" },
             { cascade_copy => 0, cascade_delete => 1 }
 );

# You can replace this text with custom content, and it will be preserved on regeneration
1;
