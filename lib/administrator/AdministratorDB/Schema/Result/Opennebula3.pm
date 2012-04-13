package AdministratorDB::Schema::Result::Opennebula3;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Opennebula3

=cut

__PACKAGE__->table("opennebula3");

=head1 ACCESSORS

=head2 opennebula3_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 install_dir

  data_type: 'char'
  default_value: '/srv/cloud/one'
  is_nullable: 0
  size: 255

=head2 host_monitoring_interval

  data_type: 'integer'
  default_value: 600
  extra: {unsigned => 1}
  is_nullable: 0

=head2 vm_polling_interval

  data_type: 'integer'
  default_value: 600
  extra: {unsigned => 1}
  is_nullable: 0

=head2 vm_dir

  data_type: 'char'
  default_value: '/srv/cloud/one/var'
  is_nullable: 0
  size: 255

=head2 scripts_remote_dir

  data_type: 'char'
  default_value: '/var/tmp/one'
  is_nullable: 0
  size: 255

=head2 image_repository_path

  data_type: 'char'
  default_value: '/srv/cloud/images'
  is_nullable: 0
  size: 255

=head2 port

  data_type: 'integer'
  default_value: 2633
  extra: {unsigned => 1}
  is_nullable: 0

=head2 debug_level

  data_type: 'enum'
  default_value: 3
  extra: {list => [0,1,2,3]}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "opennebula3_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "install_dir",
  {
    data_type => "char",
    default_value => "/srv/cloud/one",
    is_nullable => 0,
    size => 255,
  },
  "host_monitoring_interval",
  {
    data_type => "integer",
    default_value => 600,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "vm_polling_interval",
  {
    data_type => "integer",
    default_value => 600,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "vm_dir",
  {
    data_type => "char",
    default_value => "/srv/cloud/one/var",
    is_nullable => 0,
    size => 255,
  },
  "scripts_remote_dir",
  {
    data_type => "char",
    default_value => "/var/tmp/one",
    is_nullable => 0,
    size => 255,
  },
  "image_repository_path",
  {
    data_type => "char",
    default_value => "/srv/cloud/images",
    is_nullable => 0,
    size => 255,
  },
  "port",
  {
    data_type => "integer",
    default_value => 2633,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "debug_level",
  {
    data_type => "enum",
    default_value => 3,
    extra => { list => [0 .. 3] },
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("opennebula3_id");

=head1 RELATIONS

=head2 opennebula3

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "opennebula3",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "opennebula3_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 opennebula3_hypervisors

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Opennebula3Hypervisor>

=cut

__PACKAGE__->has_many(
  "opennebula3_hypervisors",
  "AdministratorDB::Schema::Result::Opennebula3Hypervisor",
  { "foreign.opennebula3_id" => "self.opennebula3_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 opennebula3_repositories

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Opennebula3Repository>

=cut

__PACKAGE__->has_many(
  "opennebula3_repositories",
  "AdministratorDB::Schema::Result::Opennebula3Repository",
  { "foreign.opennebula3_id" => "self.opennebula3_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 opennebula3_vms

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Opennebula3Vm>

=cut

__PACKAGE__->has_many(
  "opennebula3_vms",
  "AdministratorDB::Schema::Result::Opennebula3Vm",
  { "foreign.opennebula3_id" => "self.opennebula3_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-04-03 13:46:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rA2zyvgfenNBO41JrSkFYQ


__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Component",
    { "foreign.component_id" => "self.opennebula3_id" },
    { cascade_copy => 0, cascade_delete => 1 }
);

1;
