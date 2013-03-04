use utf8;
package AdministratorDB::Schema::Result::NovaController;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::NovaController

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

=head1 TABLE: C<nova_controller>

=cut

__PACKAGE__->table("nova_controller");

=head1 ACCESSORS

=head2 nova_controller_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 mysql5_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 amqp_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 keystone_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "nova_controller_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "mysql5_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "amqp_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "keystone_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</nova_controller_id>

=back

=cut

__PACKAGE__->set_primary_key("nova_controller_id");

=head1 RELATIONS

=head2 amqp

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Amqp>

=cut

__PACKAGE__->belongs_to(
  "amqp",
  "AdministratorDB::Schema::Result::Amqp",
  { amqp_id => "amqp_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 glances

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Glance>

=cut

__PACKAGE__->has_many(
  "glances",
  "AdministratorDB::Schema::Result::Glance",
  { "foreign.nova_controller_id" => "self.nova_controller_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 keystone

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Keystone>

=cut

__PACKAGE__->belongs_to(
  "keystone",
  "AdministratorDB::Schema::Result::Keystone",
  { keystone_id => "keystone_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 mysql5

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Mysql5>

=cut

__PACKAGE__->belongs_to(
  "mysql5",
  "AdministratorDB::Schema::Result::Mysql5",
  { mysql5_id => "mysql5_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 nova_controller

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Virtualization>

=cut

__PACKAGE__->belongs_to(
  "nova_controller",
  "AdministratorDB::Schema::Result::Virtualization",
  { virtualization_id => "nova_controller_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 novas_compute

Type: has_many

Related object: L<AdministratorDB::Schema::Result::NovaCompute>

=cut

__PACKAGE__->has_many(
  "novas_compute",
  "AdministratorDB::Schema::Result::NovaCompute",
  { "foreign.nova_controller_id" => "self.nova_controller_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 openstack_hypervisors

Type: has_many

Related object: L<AdministratorDB::Schema::Result::OpenstackHypervisor>

=cut

__PACKAGE__->has_many(
  "openstack_hypervisors",
  "AdministratorDB::Schema::Result::OpenstackHypervisor",
  { "foreign.nova_controller_id" => "self.nova_controller_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 openstack_vms

Type: has_many

Related object: L<AdministratorDB::Schema::Result::OpenstackVm>

=cut

__PACKAGE__->has_many(
  "openstack_vms",
  "AdministratorDB::Schema::Result::OpenstackVm",
  { "foreign.nova_controller_id" => "self.nova_controller_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 quantums

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Quantum>

=cut

__PACKAGE__->has_many(
  "quantums",
  "AdministratorDB::Schema::Result::Quantum",
  { "foreign.nova_controller_id" => "self.nova_controller_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2013-02-14 19:04:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ho4hGqTN2fe8D5SPOkySBQ

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Virtualization",
    { "foreign.virtualization_id" => "self.nova_controller_id" },
    { cascade_copy => 0, cascade_delete => 1 });

1;
