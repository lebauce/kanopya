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
);

=head1 PRIMARY KEY

=over 4

=item * L</component_id>

=back

=cut

__PACKAGE__->set_primary_key("component_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<service_provider_id>

=over 4

=item * L</service_provider_id>

=item * L</component_type_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "service_provider_id",
  ["service_provider_id", "component_type_id"],
);

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

=head2 amqp

Type: might_have

Related object: L<Kanopya::Schema::Result::Amqp>

=cut

__PACKAGE__->might_have(
  "amqp",
  "Kanopya::Schema::Result::Amqp",
  { "foreign.amqp_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 apache2

Type: might_have

Related object: L<Kanopya::Schema::Result::Apache2>

=cut

__PACKAGE__->might_have(
  "apache2",
  "Kanopya::Schema::Result::Apache2",
  { "foreign.apache2_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ceph

Type: might_have

Related object: L<Kanopya::Schema::Result::Ceph>

=cut

__PACKAGE__->might_have(
  "ceph",
  "Kanopya::Schema::Result::Ceph",
  { "foreign.ceph_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ceph_mon

Type: might_have

Related object: L<Kanopya::Schema::Result::CephMon>

=cut

__PACKAGE__->might_have(
  "ceph_mon",
  "Kanopya::Schema::Result::CephMon",
  { "foreign.ceph_mon_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ceph_osd

Type: might_have

Related object: L<Kanopya::Schema::Result::CephOsd>

=cut

__PACKAGE__->might_have(
  "ceph_osd",
  "Kanopya::Schema::Result::CephOsd",
  { "foreign.ceph_osd_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cinder

Type: might_have

Related object: L<Kanopya::Schema::Result::Cinder>

=cut

__PACKAGE__->might_have(
  "cinder",
  "Kanopya::Schema::Result::Cinder",
  { "foreign.cinder_id" => "self.component_id" },
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

=head2 dhcpd3

Type: might_have

Related object: L<Kanopya::Schema::Result::Dhcpd3>

=cut

__PACKAGE__->might_have(
  "dhcpd3",
  "Kanopya::Schema::Result::Dhcpd3",
  { "foreign.dhcpd3_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 fileimagemanager0

Type: might_have

Related object: L<Kanopya::Schema::Result::Fileimagemanager0>

=cut

__PACKAGE__->might_have(
  "fileimagemanager0",
  "Kanopya::Schema::Result::Fileimagemanager0",
  { "foreign.fileimagemanager0_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 glance

Type: might_have

Related object: L<Kanopya::Schema::Result::Glance>

=cut

__PACKAGE__->might_have(
  "glance",
  "Kanopya::Schema::Result::Glance",
  { "foreign.glance_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 haproxy1

Type: might_have

Related object: L<Kanopya::Schema::Result::Haproxy1>

=cut

__PACKAGE__->might_have(
  "haproxy1",
  "Kanopya::Schema::Result::Haproxy1",
  { "foreign.haproxy1_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 haproxy1s_listen

Type: has_many

Related object: L<Kanopya::Schema::Result::Haproxy1Listen>

=cut

__PACKAGE__->has_many(
  "haproxy1s_listen",
  "Kanopya::Schema::Result::Haproxy1Listen",
  { "foreign.listen_component_id" => "self.component_id" },
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

=head2 hpc_manager

Type: might_have

Related object: L<Kanopya::Schema::Result::HpcManager>

=cut

__PACKAGE__->might_have(
  "hpc_manager",
  "Kanopya::Schema::Result::HpcManager",
  { "foreign.hpc_manager_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 iscsi

Type: might_have

Related object: L<Kanopya::Schema::Result::Iscsi>

=cut

__PACKAGE__->might_have(
  "iscsi",
  "Kanopya::Schema::Result::Iscsi",
  { "foreign.iscsi_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 kanopya_aggregator

Type: might_have

Related object: L<Kanopya::Schema::Result::KanopyaAggregator>

=cut

__PACKAGE__->might_have(
  "kanopya_aggregator",
  "Kanopya::Schema::Result::KanopyaAggregator",
  { "foreign.kanopya_aggregator_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 kanopya_anomaly_detector

Type: might_have

Related object: L<Kanopya::Schema::Result::KanopyaAnomalyDetector>

=cut

__PACKAGE__->might_have(
  "kanopya_anomaly_detector",
  "Kanopya::Schema::Result::KanopyaAnomalyDetector",
  { "foreign.kanopya_anomaly_detector_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 kanopya_executor

Type: might_have

Related object: L<Kanopya::Schema::Result::KanopyaExecutor>

=cut

__PACKAGE__->might_have(
  "kanopya_executor",
  "Kanopya::Schema::Result::KanopyaExecutor",
  { "foreign.kanopya_executor_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 kanopya_front

Type: might_have

Related object: L<Kanopya::Schema::Result::KanopyaFront>

=cut

__PACKAGE__->might_have(
  "kanopya_front",
  "Kanopya::Schema::Result::KanopyaFront",
  { "foreign.kanopya_front_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 kanopya_mail_notifier

Type: might_have

Related object: L<Kanopya::Schema::Result::KanopyaMailNotifier>

=cut

__PACKAGE__->might_have(
  "kanopya_mail_notifier",
  "Kanopya::Schema::Result::KanopyaMailNotifier",
  { "foreign.kanopya_mail_notifier_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 kanopya_openstack_sync

Type: might_have

Related object: L<Kanopya::Schema::Result::KanopyaOpenstackSync>

=cut

__PACKAGE__->might_have(
  "kanopya_openstack_sync",
  "Kanopya::Schema::Result::KanopyaOpenstackSync",
  { "foreign.kanopya_openstack_sync_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 kanopya_rules_engine

Type: might_have

Related object: L<Kanopya::Schema::Result::KanopyaRulesEngine>

=cut

__PACKAGE__->might_have(
  "kanopya_rules_engine",
  "Kanopya::Schema::Result::KanopyaRulesEngine",
  { "foreign.kanopya_rules_engine_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 kanopya_stack_builder

Type: might_have

Related object: L<Kanopya::Schema::Result::KanopyaStackBuilder>

=cut

__PACKAGE__->might_have(
  "kanopya_stack_builder",
  "Kanopya::Schema::Result::KanopyaStackBuilder",
  { "foreign.kanopya_stack_builder_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 kanopyacollector1

Type: might_have

Related object: L<Kanopya::Schema::Result::Kanopyacollector1>

=cut

__PACKAGE__->might_have(
  "kanopyacollector1",
  "Kanopya::Schema::Result::Kanopyacollector1",
  { "foreign.kanopyacollector1_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 kanopyaworkflow0

Type: might_have

Related object: L<Kanopya::Schema::Result::Kanopyaworkflow0>

=cut

__PACKAGE__->might_have(
  "kanopyaworkflow0",
  "Kanopya::Schema::Result::Kanopyaworkflow0",
  { "foreign.kanopyaworkflow_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 keepalived1

Type: might_have

Related object: L<Kanopya::Schema::Result::Keepalived1>

=cut

__PACKAGE__->might_have(
  "keepalived1",
  "Kanopya::Schema::Result::Keepalived1",
  { "foreign.keepalived_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 keystone

Type: might_have

Related object: L<Kanopya::Schema::Result::Keystone>

=cut

__PACKAGE__->might_have(
  "keystone",
  "Kanopya::Schema::Result::Keystone",
  { "foreign.keystone_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 linux

Type: might_have

Related object: L<Kanopya::Schema::Result::Linux>

=cut

__PACKAGE__->might_have(
  "linux",
  "Kanopya::Schema::Result::Linux",
  { "foreign.linux_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 lvm2

Type: might_have

Related object: L<Kanopya::Schema::Result::Lvm2>

=cut

__PACKAGE__->might_have(
  "lvm2",
  "Kanopya::Schema::Result::Lvm2",
  { "foreign.lvm2_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 memcached1

Type: might_have

Related object: L<Kanopya::Schema::Result::Memcached1>

=cut

__PACKAGE__->might_have(
  "memcached1",
  "Kanopya::Schema::Result::Memcached1",
  { "foreign.memcached1_id" => "self.component_id" },
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

=head2 mysql5

Type: might_have

Related object: L<Kanopya::Schema::Result::Mysql5>

=cut

__PACKAGE__->might_have(
  "mysql5",
  "Kanopya::Schema::Result::Mysql5",
  { "foreign.mysql5_id" => "self.component_id" },
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

=head2 neutron

Type: might_have

Related object: L<Kanopya::Schema::Result::Neutron>

=cut

__PACKAGE__->might_have(
  "neutron",
  "Kanopya::Schema::Result::Neutron",
  { "foreign.neutron_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nfsd3

Type: might_have

Related object: L<Kanopya::Schema::Result::Nfsd3>

=cut

__PACKAGE__->might_have(
  "nfsd3",
  "Kanopya::Schema::Result::Nfsd3",
  { "foreign.nfsd3_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 openiscsi2

Type: might_have

Related object: L<Kanopya::Schema::Result::Openiscsi2>

=cut

__PACKAGE__->might_have(
  "openiscsi2",
  "Kanopya::Schema::Result::Openiscsi2",
  { "foreign.openiscsi2_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 openssh5

Type: might_have

Related object: L<Kanopya::Schema::Result::Openssh5>

=cut

__PACKAGE__->might_have(
  "openssh5",
  "Kanopya::Schema::Result::Openssh5",
  { "foreign.openssh5_id" => "self.component_id" },
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

=head2 php5

Type: might_have

Related object: L<Kanopya::Schema::Result::Php5>

=cut

__PACKAGE__->might_have(
  "php5",
  "Kanopya::Schema::Result::Php5",
  { "foreign.php5_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 physicalhoster0

Type: might_have

Related object: L<Kanopya::Schema::Result::Physicalhoster0>

=cut

__PACKAGE__->might_have(
  "physicalhoster0",
  "Kanopya::Schema::Result::Physicalhoster0",
  { "foreign.physicalhoster0_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 puppetagent2

Type: might_have

Related object: L<Kanopya::Schema::Result::Puppetagent2>

=cut

__PACKAGE__->might_have(
  "puppetagent2",
  "Kanopya::Schema::Result::Puppetagent2",
  { "foreign.puppetagent2_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 puppetmaster2

Type: might_have

Related object: L<Kanopya::Schema::Result::Puppetmaster2>

=cut

__PACKAGE__->might_have(
  "puppetmaster2",
  "Kanopya::Schema::Result::Puppetmaster2",
  { "foreign.puppetmaster2_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sco

Type: might_have

Related object: L<Kanopya::Schema::Result::Sco>

=cut

__PACKAGE__->might_have(
  "sco",
  "Kanopya::Schema::Result::Sco",
  { "foreign.sco_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
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

=head2 snmpd5

Type: might_have

Related object: L<Kanopya::Schema::Result::Snmpd5>

=cut

__PACKAGE__->might_have(
  "snmpd5",
  "Kanopya::Schema::Result::Snmpd5",
  { "foreign.snmpd5_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 storage

Type: might_have

Related object: L<Kanopya::Schema::Result::Storage>

=cut

__PACKAGE__->might_have(
  "storage",
  "Kanopya::Schema::Result::Storage",
  { "foreign.storage_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 swift_proxy

Type: might_have

Related object: L<Kanopya::Schema::Result::SwiftProxy>

=cut

__PACKAGE__->might_have(
  "swift_proxy",
  "Kanopya::Schema::Result::SwiftProxy",
  { "foreign.swift_proxy_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 swift_storage

Type: might_have

Related object: L<Kanopya::Schema::Result::SwiftStorage>

=cut

__PACKAGE__->might_have(
  "swift_storage",
  "Kanopya::Schema::Result::SwiftStorage",
  { "foreign.swift_storage_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 syslogng3

Type: might_have

Related object: L<Kanopya::Schema::Result::Syslogng3>

=cut

__PACKAGE__->might_have(
  "syslogng3",
  "Kanopya::Schema::Result::Syslogng3",
  { "foreign.syslogng3_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 tftpd

Type: might_have

Related object: L<Kanopya::Schema::Result::Tftpd>

=cut

__PACKAGE__->might_have(
  "tftpd",
  "Kanopya::Schema::Result::Tftpd",
  { "foreign.tftpd_id" => "self.component_id" },
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

=head2 virtualization

Type: might_have

Related object: L<Kanopya::Schema::Result::Virtualization>

=cut

__PACKAGE__->might_have(
  "virtualization",
  "Kanopya::Schema::Result::Virtualization",
  { "foreign.virtualization_id" => "self.component_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-04-10 17:45:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Wmh5geO6AHIQBi7BoqsZSw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
