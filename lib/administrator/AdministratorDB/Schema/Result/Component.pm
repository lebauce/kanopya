use utf8;
package AdministratorDB::Schema::Result::Component;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Component

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

Related object: L<AdministratorDB::Schema::Result::ActiveDirectory>

=cut

__PACKAGE__->might_have(
  "active_directory",
  "AdministratorDB::Schema::Result::ActiveDirectory",
  { "foreign.ad_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 apache2

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Apache2>

=cut

__PACKAGE__->might_have(
  "apache2",
  "AdministratorDB::Schema::Result::Apache2",
  { "foreign.apache2_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 atftpd0

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Atftpd0>

=cut

__PACKAGE__->might_have(
  "atftpd0",
  "AdministratorDB::Schema::Result::Atftpd0",
  { "foreign.atftpd0_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 collector_indicators

Type: has_many

Related object: L<AdministratorDB::Schema::Result::CollectorIndicator>

=cut

__PACKAGE__->has_many(
  "collector_indicators",
  "AdministratorDB::Schema::Result::CollectorIndicator",
  { "foreign.collector_manager_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 component

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "component",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "component_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 component_template

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ComponentTemplate>

=cut

__PACKAGE__->belongs_to(
  "component_template",
  "AdministratorDB::Schema::Result::ComponentTemplate",
  { component_template_id => "component_template_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 component_type

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ComponentType>

=cut

__PACKAGE__->belongs_to(
  "component_type",
  "AdministratorDB::Schema::Result::ComponentType",
  { component_type_id => "component_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 container_accesses

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ContainerAccess>

=cut

__PACKAGE__->has_many(
  "container_accesses",
  "AdministratorDB::Schema::Result::ContainerAccess",
  { "foreign.export_manager_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 dhcpd3

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Dhcpd3>

=cut

__PACKAGE__->might_have(
  "dhcpd3",
  "AdministratorDB::Schema::Result::Dhcpd3",
  { "foreign.dhcpd3_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 fileimagemanager0

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Fileimagemanager0>

=cut

__PACKAGE__->might_have(
  "fileimagemanager0",
  "AdministratorDB::Schema::Result::Fileimagemanager0",
  { "foreign.fileimagemanager0_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 haproxy1

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Haproxy1>

=cut

__PACKAGE__->might_have(
  "haproxy1",
  "AdministratorDB::Schema::Result::Haproxy1",
  { "foreign.haproxy1_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 hosts

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Host>

=cut

__PACKAGE__->has_many(
  "hosts",
  "AdministratorDB::Schema::Result::Host",
  { "foreign.host_manager_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 iscsi

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Iscsi>

=cut

__PACKAGE__->might_have(
  "iscsi",
  "AdministratorDB::Schema::Result::Iscsi",
  { "foreign.iscsi_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 kanopyacollector1

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Kanopyacollector1>

=cut

__PACKAGE__->might_have(
  "kanopyacollector1",
  "AdministratorDB::Schema::Result::Kanopyacollector1",
  { "foreign.kanopyacollector1_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 kanopyaworkflow0

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Kanopyaworkflow0>

=cut

__PACKAGE__->might_have(
  "kanopyaworkflow0",
  "AdministratorDB::Schema::Result::Kanopyaworkflow0",
  { "foreign.kanopyaworkflow_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 keepalived1

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Keepalived1>

=cut

__PACKAGE__->might_have(
  "keepalived1",
  "AdministratorDB::Schema::Result::Keepalived1",
  { "foreign.keepalived_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 linux

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Linux>

=cut

__PACKAGE__->might_have(
  "linux",
  "AdministratorDB::Schema::Result::Linux",
  { "foreign.linux_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 lvm2

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Lvm2>

=cut

__PACKAGE__->might_have(
  "lvm2",
  "AdministratorDB::Schema::Result::Lvm2",
  { "foreign.lvm2_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mailnotifier0

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Mailnotifier0>

=cut

__PACKAGE__->might_have(
  "mailnotifier0",
  "AdministratorDB::Schema::Result::Mailnotifier0",
  { "foreign.mailnotifier0_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 memcached1

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Memcached1>

=cut

__PACKAGE__->might_have(
  "memcached1",
  "AdministratorDB::Schema::Result::Memcached1",
  { "foreign.memcached1_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mock_monitor

Type: might_have

Related object: L<AdministratorDB::Schema::Result::MockMonitor>

=cut

__PACKAGE__->might_have(
  "mock_monitor",
  "AdministratorDB::Schema::Result::MockMonitor",
  { "foreign.mock_monitor_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mysql5

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Mysql5>

=cut

__PACKAGE__->might_have(
  "mysql5",
  "AdministratorDB::Schema::Result::Mysql5",
  { "foreign.mysql5_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 netapp_lun_manager

Type: might_have

Related object: L<AdministratorDB::Schema::Result::NetappLunManager>

=cut

__PACKAGE__->might_have(
  "netapp_lun_manager",
  "AdministratorDB::Schema::Result::NetappLunManager",
  { "foreign.netapp_lun_manager_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 netapp_volume_manager

Type: might_have

Related object: L<AdministratorDB::Schema::Result::NetappVolumeManager>

=cut

__PACKAGE__->might_have(
  "netapp_volume_manager",
  "AdministratorDB::Schema::Result::NetappVolumeManager",
  { "foreign.netapp_volume_manager_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nfsd3

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Nfsd3>

=cut

__PACKAGE__->might_have(
  "nfsd3",
  "AdministratorDB::Schema::Result::Nfsd3",
  { "foreign.nfsd3_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 openiscsi2

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Openiscsi2>

=cut

__PACKAGE__->might_have(
  "openiscsi2",
  "AdministratorDB::Schema::Result::Openiscsi2",
  { "foreign.openiscsi2_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 openldap1

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Openldap1>

=cut

__PACKAGE__->might_have(
  "openldap1",
  "AdministratorDB::Schema::Result::Openldap1",
  { "foreign.openldap1_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 opennebula3

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Opennebula3>

=cut

__PACKAGE__->might_have(
  "opennebula3",
  "AdministratorDB::Schema::Result::Opennebula3",
  { "foreign.opennebula3_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 openssh5

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Openssh5>

=cut

__PACKAGE__->might_have(
  "openssh5",
  "AdministratorDB::Schema::Result::Openssh5",
  { "foreign.openssh5_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 php5

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Php5>

=cut

__PACKAGE__->might_have(
  "php5",
  "AdministratorDB::Schema::Result::Php5",
  { "foreign.php5_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 physicalhoster0

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Physicalhoster0>

=cut

__PACKAGE__->might_have(
  "physicalhoster0",
  "AdministratorDB::Schema::Result::Physicalhoster0",
  { "foreign.physicalhoster0_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 puppetagent2

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Puppetagent2>

=cut

__PACKAGE__->might_have(
  "puppetagent2",
  "AdministratorDB::Schema::Result::Puppetagent2",
  { "foreign.puppetagent2_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 puppetmaster2

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Puppetmaster2>

=cut

__PACKAGE__->might_have(
  "puppetmaster2",
  "AdministratorDB::Schema::Result::Puppetmaster2",
  { "foreign.puppetmaster2_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sco

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Sco>

=cut

__PACKAGE__->might_have(
  "sco",
  "AdministratorDB::Schema::Result::Sco",
  { "foreign.sco_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 scom

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Scom>

=cut

__PACKAGE__->might_have(
  "scom",
  "AdministratorDB::Schema::Result::Scom",
  { "foreign.scom_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_provider

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "service_provider",
  "AdministratorDB::Schema::Result::ServiceProvider",
  { service_provider_id => "service_provider_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 service_provider_managers

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ServiceProviderManager>

=cut

__PACKAGE__->has_many(
  "service_provider_managers",
  "AdministratorDB::Schema::Result::ServiceProviderManager",
  { "foreign.manager_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 snmpd5

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Snmpd5>

=cut

__PACKAGE__->might_have(
  "snmpd5",
  "AdministratorDB::Schema::Result::Snmpd5",
  { "foreign.snmpd5_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 storage

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Storage>

=cut

__PACKAGE__->might_have(
  "storage",
  "AdministratorDB::Schema::Result::Storage",
  { "foreign.storage_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 syslogng3

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Syslogng3>

=cut

__PACKAGE__->might_have(
  "syslogng3",
  "AdministratorDB::Schema::Result::Syslogng3",
  { "foreign.syslogng3_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ucs_manager

Type: might_have

Related object: L<AdministratorDB::Schema::Result::UcsManager>

=cut

__PACKAGE__->might_have(
  "ucs_manager",
  "AdministratorDB::Schema::Result::UcsManager",
  { "foreign.ucs_manager_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vmm_iaas

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Vmm>

=cut

__PACKAGE__->has_many(
  "vmm_iaas",
  "AdministratorDB::Schema::Result::Vmm",
  { "foreign.iaas_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vmm_vmm

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Vmm>

=cut

__PACKAGE__->might_have(
  "vmm_vmm",
  "AdministratorDB::Schema::Result::Vmm",
  { "foreign.vmm_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vsphere5

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Vsphere5>

=cut

__PACKAGE__->might_have(
  "vsphere5",
  "AdministratorDB::Schema::Result::Vsphere5",
  { "foreign.vsphere5_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workflow_def_managers

Type: has_many

Related object: L<AdministratorDB::Schema::Result::WorkflowDefManager>

=cut

__PACKAGE__->has_many(
  "workflow_def_managers",
  "AdministratorDB::Schema::Result::WorkflowDefManager",
  { "foreign.manager_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2013-02-04 17:48:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Z8mK8iBtsdiU4Tcny/Racw

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "component_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->has_many(
  "vmms",
  "AdministratorDB::Schema::Result::Vmm",
  { "foreign.iaas_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->might_have(
  "vmm",
  "AdministratorDB::Schema::Result::Vmm",
  { "foreign.vmm_id" => "self.component_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
