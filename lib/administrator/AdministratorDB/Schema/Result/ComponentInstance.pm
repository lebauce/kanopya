package AdministratorDB::Schema::Result::ComponentInstance;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::ComponentInstance

=cut

__PACKAGE__->table("component_instance");

=head1 ACCESSORS

=head2 component_instance_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 cluster_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 component_id

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
  "component_instance_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "cluster_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "component_id",
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
__PACKAGE__->set_primary_key("component_instance_id");

=head1 RELATIONS

=head2 apache2s

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Apache2>

=cut

#__PACKAGE__->has_many(
#  "apache2s",
#  "AdministratorDB::Schema::Result::Apache2",
#  { "foreign.component_instance_id" => "self.component_instance_id" },
#  { cascade_copy => 0, cascade_delete => 0 },
#);

=head2 atftpd0s

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Atftpd0>

=cut

__PACKAGE__->has_many(
  "atftpd0s",
  "AdministratorDB::Schema::Result::Atftpd0",
  { "foreign.component_instance_id" => "self.component_instance_id" },
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
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 component_template

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ComponentTemplate>

=cut

__PACKAGE__->belongs_to(
  "component_template",
  "AdministratorDB::Schema::Result::ComponentTemplate",
  { component_template_id => "component_template_id" },
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 component

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "component",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "component_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 component_instance_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::ComponentInstanceEntity>

=cut

__PACKAGE__->might_have(
  "component_instance_entity",
  "AdministratorDB::Schema::Result::ComponentInstanceEntity",
  { "foreign.component_instance_id" => "self.component_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 dhcpd3s

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Dhcpd3>

=cut

__PACKAGE__->has_many(
  "dhcpd3s",
  "AdministratorDB::Schema::Result::Dhcpd3",
  { "foreign.component_instance_id" => "self.component_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 iscsitarget1_targets

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Iscsitarget1Target>

=cut

__PACKAGE__->has_many(
  "iscsitarget1_targets",
  "AdministratorDB::Schema::Result::Iscsitarget1Target",
  { "foreign.component_instance_id" => "self.component_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 keepalived1

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Keepalived1>

=cut

__PACKAGE__->might_have(
  "keepalived1",
  "AdministratorDB::Schema::Result::Keepalived1",
  { "foreign.component_instance_id" => "self.component_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 lvm2_vgs

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Lvm2Vg>

=cut

__PACKAGE__->has_many(
  "lvm2_vgs",
  "AdministratorDB::Schema::Result::Lvm2Vg",
  { "foreign.component_instance_id" => "self.component_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 memcached1s

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Memcached1>

=cut

__PACKAGE__->has_many(
  "memcached1s",
  "AdministratorDB::Schema::Result::Memcached1",
  { "foreign.component_instance_id" => "self.component_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mounttable1s

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Mounttable1>

=cut

__PACKAGE__->has_many(
  "mounttable1s",
  "AdministratorDB::Schema::Result::Mounttable1",
  { "foreign.component_instance_id" => "self.component_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nfsd3s

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Nfsd3>

=cut

__PACKAGE__->has_many(
  "nfsd3s",
  "AdministratorDB::Schema::Result::Nfsd3",
  { "foreign.component_instance_id" => "self.component_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 openiscsi2s

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Openiscsi2>

=cut

__PACKAGE__->has_many(
  "openiscsi2s",
  "AdministratorDB::Schema::Result::Openiscsi2",
  { "foreign.component_instance_id" => "self.component_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 php5s

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Php5>

=cut

#__PACKAGE__->has_many(
#  "php5s",
#  "AdministratorDB::Schema::Result::Php5",
#  { "foreign.component_instance_id" => "self.component_instance_id" },
#  { cascade_copy => 0, cascade_delete => 0 },
#);

=head2 snmpd5s

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Snmpd5>

=cut

__PACKAGE__->has_many(
  "snmpd5s",
  "AdministratorDB::Schema::Result::Snmpd5",
  { "foreign.component_instance_id" => "self.component_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 syslogng3s

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Syslogng3>

=cut

__PACKAGE__->has_many(
  "syslogng3s",
  "AdministratorDB::Schema::Result::Syslogng3",
  { "foreign.component_instance_id" => "self.component_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-05-04 15:05:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XKBAccz1BPd0drl4orRjlA



# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::Result::ComponentInstanceEntity",
    { "foreign.component_instance_id" => "self.component_instance_id" },
    { cascade_copy => 0, cascade_delete => 0 });


#########################################
# Load components relationship
#########################################
# Get list of component instance relathionship files
opendir(DIR, "/opt/kanopya/lib/administrator/AdministratorDB/Component");
my @comp_files = readdir(DIR);
closedir(DIR);
# Load components relationship
for my $comp_file (@comp_files) {
	if ($comp_file =~ /(.*)\.pm/) {
		__PACKAGE__->load_components("+AdministratorDB::Component::$1");
	}
}

1;
