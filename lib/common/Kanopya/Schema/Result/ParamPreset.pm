use utf8;
package Kanopya::Schema::Result::ParamPreset;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::ParamPreset

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

=head1 TABLE: C<param_preset>

=cut

__PACKAGE__->table("param_preset");

=head1 ACCESSORS

=head2 param_preset_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 params

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "param_preset_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "params",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</param_preset_id>

=back

=cut

__PACKAGE__->set_primary_key("param_preset_id");

=head1 RELATIONS

=head2 components

Type: has_many

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->has_many(
  "components",
  "Kanopya::Schema::Result::Component",
  { "foreign.param_preset_id" => "self.param_preset_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 data_models

Type: has_many

Related object: L<Kanopya::Schema::Result::DataModel>

=cut

__PACKAGE__->has_many(
  "data_models",
  "Kanopya::Schema::Result::DataModel",
  { "foreign.param_preset_id" => "self.param_preset_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 old_operations

Type: has_many

Related object: L<Kanopya::Schema::Result::OldOperation>

=cut

__PACKAGE__->has_many(
  "old_operations",
  "Kanopya::Schema::Result::OldOperation",
  { "foreign.param_preset_id" => "self.param_preset_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 operations

Type: has_many

Related object: L<Kanopya::Schema::Result::Operation>

=cut

__PACKAGE__->has_many(
  "operations",
  "Kanopya::Schema::Result::Operation",
  { "foreign.param_preset_id" => "self.param_preset_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 policies

Type: has_many

Related object: L<Kanopya::Schema::Result::Policy>

=cut

__PACKAGE__->has_many(
  "policies",
  "Kanopya::Schema::Result::Policy",
  { "foreign.param_preset_id" => "self.param_preset_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_provider_managers

Type: has_many

Related object: L<Kanopya::Schema::Result::ServiceProviderManager>

=cut

__PACKAGE__->has_many(
  "service_provider_managers",
  "Kanopya::Schema::Result::ServiceProviderManager",
  { "foreign.param_preset_id" => "self.param_preset_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 time_periods

Type: has_many

Related object: L<Kanopya::Schema::Result::TimePeriod>

=cut

__PACKAGE__->has_many(
  "time_periods",
  "Kanopya::Schema::Result::TimePeriod",
  { "foreign.param_preset_id" => "self.param_preset_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workflow_def_rules

Type: has_many

Related object: L<Kanopya::Schema::Result::WorkflowDefRule>

=cut

__PACKAGE__->has_many(
  "workflow_def_rules",
  "Kanopya::Schema::Result::WorkflowDefRule",
  { "foreign.param_preset_id" => "self.param_preset_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workflow_defs

Type: has_many

Related object: L<Kanopya::Schema::Result::WorkflowDef>

=cut

__PACKAGE__->has_many(
  "workflow_defs",
  "Kanopya::Schema::Result::WorkflowDef",
  { "foreign.param_preset_id" => "self.param_preset_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-03-03 12:34:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LccuVtCfrbD7Egbcduih6w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
