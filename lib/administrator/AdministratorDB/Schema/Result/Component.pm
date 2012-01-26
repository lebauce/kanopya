package AdministratorDB::Schema::Result::Component;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Component

=cut

__PACKAGE__->table("component");

=head1 ACCESSORS

=head2 component_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 cluster_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 component_type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 tier_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 component_template_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "component_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "cluster_id",
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
  "tier_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "component_template_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("component_id");

=head1 RELATIONS

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

=head2 cluster

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Cluster>

=cut

__PACKAGE__->belongs_to(
  "cluster",
  "AdministratorDB::Schema::Result::Cluster",
  { cluster_id => "cluster_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
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

=head2 tier

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Tier>

=cut

__PACKAGE__->belongs_to(
  "tier",
  "AdministratorDB::Schema::Result::Tier",
  { tier_id => "tier_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
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

=head2 iscsitarget1

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Iscsitarget1>

=cut

__PACKAGE__->might_have(
  "iscsitarget1",
  "AdministratorDB::Schema::Result::Iscsitarget1",
  { "foreign.iscsitarget1_id" => "self.component_id" },
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

=head2 mounttable1

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Mounttable1>

=cut

__PACKAGE__->might_have(
  "mounttable1",
  "AdministratorDB::Schema::Result::Mounttable1",
  { "foreign.mounttable1_id" => "self.component_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-26 17:01:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:49StHrs4TdgwUAVhlDlKPg


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
    { "foreign.entity_id" => "self.component_id" },
    { cascade_copy => 0, cascade_delete => 1 });
1;
