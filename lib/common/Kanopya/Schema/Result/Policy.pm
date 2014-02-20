use utf8;
package Kanopya::Schema::Result::Policy;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Policy

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

=head1 TABLE: C<policy>

=cut

__PACKAGE__->table("policy");

=head1 ACCESSORS

=head2 policy_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 param_preset_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 policy_name

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 policy_desc

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 policy_type

  data_type: 'char'
  is_nullable: 0
  size: 64

=cut

__PACKAGE__->add_columns(
  "policy_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "param_preset_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "policy_name",
  { data_type => "char", is_nullable => 0, size => 64 },
  "policy_desc",
  { data_type => "char", is_nullable => 1, size => 255 },
  "policy_type",
  { data_type => "char", is_nullable => 0, size => 64 },
);

=head1 PRIMARY KEY

=over 4

=item * L</policy_id>

=back

=cut

__PACKAGE__->set_primary_key("policy_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<policy_name>

=over 4

=item * L</policy_name>

=back

=cut

__PACKAGE__->add_unique_constraint("policy_name", ["policy_name"]);

=head1 RELATIONS

=head2 param_preset

Type: belongs_to

Related object: L<Kanopya::Schema::Result::ParamPreset>

=cut

__PACKAGE__->belongs_to(
  "param_preset",
  "Kanopya::Schema::Result::ParamPreset",
  { param_preset_id => "param_preset_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);

=head2 policy

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "policy",
  "Kanopya::Schema::Result::Entity",
  { entity_id => "policy_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 service_template_billing_policies

Type: has_many

Related object: L<Kanopya::Schema::Result::ServiceTemplate>

=cut

__PACKAGE__->has_many(
  "service_template_billing_policies",
  "Kanopya::Schema::Result::ServiceTemplate",
  { "foreign.billing_policy_id" => "self.policy_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_template_hosting_policies

Type: has_many

Related object: L<Kanopya::Schema::Result::ServiceTemplate>

=cut

__PACKAGE__->has_many(
  "service_template_hosting_policies",
  "Kanopya::Schema::Result::ServiceTemplate",
  { "foreign.hosting_policy_id" => "self.policy_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_template_network_policies

Type: has_many

Related object: L<Kanopya::Schema::Result::ServiceTemplate>

=cut

__PACKAGE__->has_many(
  "service_template_network_policies",
  "Kanopya::Schema::Result::ServiceTemplate",
  { "foreign.network_policy_id" => "self.policy_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_template_orchestration_policies

Type: has_many

Related object: L<Kanopya::Schema::Result::ServiceTemplate>

=cut

__PACKAGE__->has_many(
  "service_template_orchestration_policies",
  "Kanopya::Schema::Result::ServiceTemplate",
  { "foreign.orchestration_policy_id" => "self.policy_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_template_scalability_policies

Type: has_many

Related object: L<Kanopya::Schema::Result::ServiceTemplate>

=cut

__PACKAGE__->has_many(
  "service_template_scalability_policies",
  "Kanopya::Schema::Result::ServiceTemplate",
  { "foreign.scalability_policy_id" => "self.policy_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_template_storage_policies

Type: has_many

Related object: L<Kanopya::Schema::Result::ServiceTemplate>

=cut

__PACKAGE__->has_many(
  "service_template_storage_policies",
  "Kanopya::Schema::Result::ServiceTemplate",
  { "foreign.storage_policy_id" => "self.policy_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_template_system_policies

Type: has_many

Related object: L<Kanopya::Schema::Result::ServiceTemplate>

=cut

__PACKAGE__->has_many(
  "service_template_system_policies",
  "Kanopya::Schema::Result::ServiceTemplate",
  { "foreign.system_policy_id" => "self.policy_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-02-04 16:46:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XOPu2sA4c+LPHswKscY1WQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
