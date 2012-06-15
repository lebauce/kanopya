use utf8;
package AdministratorDB::Schema::Result::Component;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Component

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

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

=head1 PRIMARY KEY

=over 4

=item * L</component_id>

=back

=cut

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

=head2 linux0

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Linux0>

=cut

__PACKAGE__->might_have(
  "linux0",
  "AdministratorDB::Schema::Result::Linux0",
  { "foreign.linux0_id" => "self.component_id" },
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

=head2 service_provider

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Inside>

=cut

__PACKAGE__->belongs_to(
  "service_provider",
  "AdministratorDB::Schema::Result::Inside",
  { inside_id => "service_provider_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
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


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-06-14 15:52:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/KoQlMf4P0QcBgq3PBV8LQ

# You can replace this text with custom code or comments, and it will be preserved on regeneration

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
    { "foreign.entity_id" => "self.component_id" },
    { cascade_copy => 0, cascade_delete => 1 }
);

1;
