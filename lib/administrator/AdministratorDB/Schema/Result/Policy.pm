use utf8;
package AdministratorDB::Schema::Result::Policy;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Policy

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

=head1 RELATIONS

=head2 billing_policy

Type: might_have

Related object: L<AdministratorDB::Schema::Result::BillingPolicy>

=cut

__PACKAGE__->might_have(
  "billing_policy",
  "AdministratorDB::Schema::Result::BillingPolicy",
  { "foreign.billing_policy_id" => "self.policy_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 hosting_policy

Type: might_have

Related object: L<AdministratorDB::Schema::Result::HostingPolicy>

=cut

__PACKAGE__->might_have(
  "hosting_policy",
  "AdministratorDB::Schema::Result::HostingPolicy",
  { "foreign.hosting_policy_id" => "self.policy_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 network_policy

Type: might_have

Related object: L<AdministratorDB::Schema::Result::NetworkPolicy>

=cut

__PACKAGE__->might_have(
  "network_policy",
  "AdministratorDB::Schema::Result::NetworkPolicy",
  { "foreign.network_policy_id" => "self.policy_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 orchestration_policy

Type: might_have

Related object: L<AdministratorDB::Schema::Result::OrchestrationPolicy>

=cut

__PACKAGE__->might_have(
  "orchestration_policy",
  "AdministratorDB::Schema::Result::OrchestrationPolicy",
  { "foreign.orchestration_policy_id" => "self.policy_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 param_preset

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ParamPreset>

=cut

__PACKAGE__->belongs_to(
  "param_preset",
  "AdministratorDB::Schema::Result::ParamPreset",
  { param_preset_id => "param_preset_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 policy

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "policy",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "policy_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 scalability_policy

Type: might_have

Related object: L<AdministratorDB::Schema::Result::ScalabilityPolicy>

=cut

__PACKAGE__->might_have(
  "scalability_policy",
  "AdministratorDB::Schema::Result::ScalabilityPolicy",
  { "foreign.scalability_policy_id" => "self.policy_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 storage_policy

Type: might_have

Related object: L<AdministratorDB::Schema::Result::StoragePolicy>

=cut

__PACKAGE__->might_have(
  "storage_policy",
  "AdministratorDB::Schema::Result::StoragePolicy",
  { "foreign.storage_policy_id" => "self.policy_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 system_policy

Type: might_have

Related object: L<AdministratorDB::Schema::Result::SystemPolicy>

=cut

__PACKAGE__->might_have(
  "system_policy",
  "AdministratorDB::Schema::Result::SystemPolicy",
  { "foreign.system_policy_id" => "self.policy_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-12-06 10:18:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:b6ZTqFHVsQQNKg+FWwC4MA

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "policy_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
