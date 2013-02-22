use utf8;
package AdministratorDB::Schema::Result::Rule;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Rule

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

Related object: L<AdministratorDB::Schema::Result::AggregateRule>

=cut

__PACKAGE__->might_have(
  "aggregate_rule",
  "AdministratorDB::Schema::Result::AggregateRule",
  { "foreign.aggregate_rule_id" => "self.rule_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nodemetric_rule

Type: might_have

Related object: L<AdministratorDB::Schema::Result::NodemetricRule>

=cut

__PACKAGE__->might_have(
  "nodemetric_rule",
  "AdministratorDB::Schema::Result::NodemetricRule",
  { "foreign.nodemetric_rule_id" => "self.rule_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 rule

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "rule",
  "AdministratorDB::Schema::Result::Entity",
  { "foreign.entity_id" => "self.rule_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


=head2 service_provider

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "service_provider",
  "AdministratorDB::Schema::Result::ServiceProvider",
  { service_provider_id => "service_provider_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2013-02-22 14:20:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sV9iPSVEdvskEgkATmpPow


 __PACKAGE__->belongs_to(
    "parent",
    "AdministratorDB::Schema::Result::Entity",
    { "foreign.entity_id" => "self.rule_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
 );

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
