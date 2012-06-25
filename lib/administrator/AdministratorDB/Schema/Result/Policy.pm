package AdministratorDB::Schema::Result::Policy;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Policy

=cut

__PACKAGE__->table("policy");

=head1 ACCESSORS

=head2 policy_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 param_preset_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

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
  is_nullable: 1
  size: 64

=cut

__PACKAGE__->add_columns(
  "policy_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "param_preset_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "policy_name",
  { data_type => "char", is_nullable => 0, size => 64 },
  "policy_desc",
  { data_type => "char", is_nullable => 1, size => 255 },
  "policy_type",
  { data_type => "char", is_nullable => 1, size => 64 },
);
__PACKAGE__->set_primary_key("policy_id");

=head1 RELATIONS

=head2 param_preset

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ParamPreset>

=cut

__PACKAGE__->belongs_to(
  "param_preset",
  "AdministratorDB::Schema::Result::ParamPreset",
  { param_preset_id => "param_preset_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 service_template_hosting_policies

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ServiceTemplate>

=cut

__PACKAGE__->has_many(
  "service_template_hosting_policies",
  "AdministratorDB::Schema::Result::ServiceTemplate",
  { "foreign.hosting_policy_id" => "self.policy_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_template_storage_policies

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ServiceTemplate>

=cut

__PACKAGE__->has_many(
  "service_template_storage_policies",
  "AdministratorDB::Schema::Result::ServiceTemplate",
  { "foreign.storage_policy_id" => "self.policy_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_template_network_policies

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ServiceTemplate>

=cut

__PACKAGE__->has_many(
  "service_template_network_policies",
  "AdministratorDB::Schema::Result::ServiceTemplate",
  { "foreign.network_policy_id" => "self.policy_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_template_scalability_policies

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ServiceTemplate>

=cut

__PACKAGE__->has_many(
  "service_template_scalability_policies",
  "AdministratorDB::Schema::Result::ServiceTemplate",
  { "foreign.scalability_policy_id" => "self.policy_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_template_system_policies

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ServiceTemplate>

=cut

__PACKAGE__->has_many(
  "service_template_system_policies",
  "AdministratorDB::Schema::Result::ServiceTemplate",
  { "foreign.system_policy_id" => "self.policy_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-06-12 10:46:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xD4u90MCM08kCzYF4PvuJg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
