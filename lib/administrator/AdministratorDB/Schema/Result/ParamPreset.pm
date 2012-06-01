package AdministratorDB::Schema::Result::ParamPreset;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::ParamPreset

=cut

__PACKAGE__->table("param_preset");

=head1 ACCESSORS

=head2 param_preset_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'char'
  is_nullable: 1
  size: 128

=head2 value

  data_type: 'char'
  is_nullable: 1
  size: 128

=head2 relation

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
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
  "name",
  { data_type => "char", is_nullable => 1, size => 128 },
  "value",
  { data_type => "char", is_nullable => 1, size => 128 },
  "relation",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("param_preset_id");

=head1 RELATIONS

=head2 cluster_managers

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ClusterManager>

=cut

__PACKAGE__->has_many(
  "cluster_managers",
  "AdministratorDB::Schema::Result::ClusterManager",
  { "foreign.manager_params" => "self.param_preset_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 relation

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ParamPreset>

=cut

__PACKAGE__->belongs_to(
  "relation",
  "AdministratorDB::Schema::Result::ParamPreset",
  { param_preset_id => "relation" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 param_presets

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ParamPreset>

=cut

__PACKAGE__->has_many(
  "param_presets",
  "AdministratorDB::Schema::Result::ParamPreset",
  { "foreign.relation" => "self.param_preset_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 policies

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Policy>

=cut

__PACKAGE__->has_many(
  "policies",
  "AdministratorDB::Schema::Result::Policy",
  { "foreign.param_preset_id" => "self.param_preset_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workflow_defs

Type: has_many

Related object: L<AdministratorDB::Schema::Result::WorkflowDef>

=cut

__PACKAGE__->has_many(
  "workflow_defs",
  "AdministratorDB::Schema::Result::WorkflowDef",
  { "foreign.param_preset_id" => "self.param_preset_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-06-01 10:34:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:C5dvL1FIXrROXluckHSVqA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
