use utf8;
package AdministratorDB::Schema::Result::VerifiedNoderule;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::VerifiedNoderule

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

=head1 TABLE: C<verified_noderule>

=cut

__PACKAGE__->table("verified_noderule");

=head1 ACCESSORS

=head2 verified_noderule_node_id

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

=cut

__PACKAGE__->add_columns(
  "verified_noderule_node_id",
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
);

=head1 PRIMARY KEY

=over 4

=item * L</verified_noderule_node_id>

=item * L</verified_noderule_nodemetric_rule_id>

=back

=cut

__PACKAGE__->set_primary_key(
  "verified_noderule_node_id",
  "verified_noderule_nodemetric_rule_id",
);

=head1 RELATIONS

=head2 verified_noderule_node

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Node>

=cut

__PACKAGE__->belongs_to(
  "verified_noderule_node",
  "AdministratorDB::Schema::Result::Node",
  { node_id => "verified_noderule_node_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2013-02-04 17:48:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3WhTAPejk4tPMHR8MqxVww


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
