use utf8;
package Kanopya::Schema::Result::Rule;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Rule

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

=head1 TABLE: C<rule>

=cut

__PACKAGE__->table("rule");

=head1 ACCESSORS

=head2 rule_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 service_provider_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 rule_name

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 formula

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 formula_string

  data_type: 'text'
  is_nullable: 1

=head2 timestamp

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 state

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 workflow_def_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "rule_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "service_provider_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "rule_name",
  { data_type => "char", is_nullable => 1, size => 255 },
  "formula",
  { data_type => "char", is_nullable => 0, size => 255 },
  "formula_string",
  { data_type => "text", is_nullable => 1 },
  "timestamp",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "state",
  { data_type => "char", is_nullable => 0, size => 32 },
  "description",
  { data_type => "text", is_nullable => 1 },
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

=item * L</rule_id>

=back

=cut

__PACKAGE__->set_primary_key("rule_id");

=head1 RELATIONS

=head2 aggregate_rule

Type: might_have

Related object: L<Kanopya::Schema::Result::AggregateRule>

=cut

__PACKAGE__->might_have(
  "aggregate_rule",
  "Kanopya::Schema::Result::AggregateRule",
  { "foreign.aggregate_rule_id" => "self.rule_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nodemetric_rule

Type: might_have

Related object: L<Kanopya::Schema::Result::NodemetricRule>

=cut

__PACKAGE__->might_have(
  "nodemetric_rule",
  "Kanopya::Schema::Result::NodemetricRule",
  { "foreign.nodemetric_rule_id" => "self.rule_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 rule

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "rule",
  "Kanopya::Schema::Result::Entity",
  { entity_id => "rule_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 ruleconditions

Type: has_many

Related object: L<Kanopya::Schema::Result::Rulecondition>

=cut

__PACKAGE__->has_many(
  "ruleconditions",
  "Kanopya::Schema::Result::Rulecondition",
  { "foreign.rule_id" => "self.rule_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_provider

Type: belongs_to

Related object: L<Kanopya::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "service_provider",
  "Kanopya::Schema::Result::ServiceProvider",
  { service_provider_id => "service_provider_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 workflow_def

Type: belongs_to

Related object: L<Kanopya::Schema::Result::WorkflowDef>

=cut

__PACKAGE__->belongs_to(
  "workflow_def",
  "Kanopya::Schema::Result::WorkflowDef",
  { workflow_def_id => "workflow_def_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nDLILau7l34hW0lUsDsD1g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
