use utf8;
package Kanopya::Schema::Result::Component;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Component

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

=head1 TABLE: C<component>

=cut

__PACKAGE__->table("component");

=head1 ACCESSORS

=head2 component_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 service_provider_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 component_type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 component_template_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 param_preset_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 executor_component_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "component_id",
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
    is_nullable => 1,
  },
  "component_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "component_template_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "param_preset_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "executor_component_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</component_id>

=back

=cut

__PACKAGE__->set_primary_key("component_id");

=head1 RELATIONS

=head2 active_directory

Type: might_have

Related object: L<Kanopya::Schema::Result::ActiveDirectory>

=cut

__PACKAGE__->might_have(
  "active_directory",
  "Kanopya::Schema::Result::ActiveDirectory",
  { "foreign.ad_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 collector_indicators

Type: has_many

Related object: L<Kanopya::Schema::Result::CollectorIndicator>

=cut

__PACKAGE__->has_many(
  "collector_indicators",
  "Kanopya::Schema::Result::CollectorIndicator",
  { "foreign.collector_manager_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 component

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "component",
  "Kanopya::Schema::Result::Entity",
  { entity_id => "component_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 component_nodes

Type: has_many

Related object: L<Kanopya::Schema::Result::ComponentNode>

=cut

__PACKAGE__->has_many(
  "component_nodes",
  "Kanopya::Schema::Result::ComponentNode",
  { "foreign.component_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 component_template

Type: belongs_to

Related object: L<Kanopya::Schema::Result::ComponentTemplate>

=cut

__PACKAGE__->belongs_to(
  "component_template",
  "Kanopya::Schema::Result::ComponentTemplate",
  { component_template_id => "component_template_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 component_type

Type: belongs_to

Related object: L<Kanopya::Schema::Result::ComponentType>

=cut

__PACKAGE__->belongs_to(
  "component_type",
  "Kanopya::Schema::Result::ComponentType",
  { component_type_id => "component_type_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 container_accesses

Type: has_many

Related object: L<Kanopya::Schema::Result::ContainerAccess>

=cut

__PACKAGE__->has_many(
  "container_accesses",
  "Kanopya::Schema::Result::ContainerAccess",
  { "foreign.export_manager_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 containers

Type: has_many

Related object: L<Kanopya::Schema::Result::Container>

=cut

__PACKAGE__->has_many(
  "containers",
  "Kanopya::Schema::Result::Container",
  { "foreign.disk_manager_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 hosts

Type: has_many

Related object: L<Kanopya::Schema::Result::Host>

=cut

__PACKAGE__->has_many(
  "hosts",
  "Kanopya::Schema::Result::Host",
  { "foreign.host_manager_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mock_monitor

Type: might_have

Related object: L<Kanopya::Schema::Result::MockMonitor>

=cut

__PACKAGE__->might_have(
  "mock_monitor",
  "Kanopya::Schema::Result::MockMonitor",
  { "foreign.mock_monitor_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 netapp_lun_manager

Type: might_have

Related object: L<Kanopya::Schema::Result::NetappLunManager>

=cut

__PACKAGE__->might_have(
  "netapp_lun_manager",
  "Kanopya::Schema::Result::NetappLunManager",
  { "foreign.netapp_lun_manager_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 netapp_volume_manager

Type: might_have

Related object: L<Kanopya::Schema::Result::NetappVolumeManager>

=cut

__PACKAGE__->might_have(
  "netapp_volume_manager",
  "Kanopya::Schema::Result::NetappVolumeManager",
  { "foreign.netapp_volume_manager_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

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

=head2 scom

Type: might_have

Related object: L<Kanopya::Schema::Result::Scom>

=cut

__PACKAGE__->might_have(
  "scom",
  "Kanopya::Schema::Result::Scom",
  { "foreign.scom_id" => "self.component_id" },
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
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 service_provider_managers

Type: has_many

Related object: L<Kanopya::Schema::Result::ServiceProviderManager>

=cut

__PACKAGE__->has_many(
  "service_provider_managers",
  "Kanopya::Schema::Result::ServiceProviderManager",
  { "foreign.manager_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_providers

Type: has_many

Related object: L<Kanopya::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->has_many(
  "service_providers",
  "Kanopya::Schema::Result::ServiceProvider",
  { "foreign.service_manager_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ucs_manager

Type: might_have

Related object: L<Kanopya::Schema::Result::UcsManager>

=cut

__PACKAGE__->might_have(
  "ucs_manager",
  "Kanopya::Schema::Result::UcsManager",
  { "foreign.ucs_manager_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vmm

Type: might_have

Related object: L<Kanopya::Schema::Result::Vmm>

=cut

__PACKAGE__->might_have(
  "vmm",
  "Kanopya::Schema::Result::Vmm",
  { "foreign.vmm_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workflow_def_managers

Type: has_many

Related object: L<Kanopya::Schema::Result::WorkflowDefManager>

=cut

__PACKAGE__->has_many(
  "workflow_def_managers",
  "Kanopya::Schema::Result::WorkflowDefManager",
  { "foreign.manager_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workflow_defs

Type: many_to_many

Composing rels: L</workflow_def_managers> -> workflow_def

=cut

__PACKAGE__->many_to_many("workflow_defs", "workflow_def_managers", "workflow_def");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-06-27 12:03:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7KRzp+rSaTrOS11ifZrViQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
