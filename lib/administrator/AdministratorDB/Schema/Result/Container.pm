package AdministratorDB::Schema::Result::Container;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Container

=cut

__PACKAGE__->table("container");

=head1 ACCESSORS

=head2 container_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 service_provider_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 disk_manager_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "container_id",
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
    is_nullable => 0,
  },
  "disk_manager_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("container_id");

=head1 RELATIONS

=head2 container

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "container",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "container_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 service_provider

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "service_provider",
  "AdministratorDB::Schema::Result::ServiceProvider",
  { service_provider_id => "service_provider_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 container_accesses

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ContainerAccess>

=cut

__PACKAGE__->has_many(
  "container_accesses",
  "AdministratorDB::Schema::Result::ContainerAccess",
  { "foreign.container_id" => "self.container_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 distribution_etc_containers

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Distribution>

=cut

__PACKAGE__->has_many(
  "distribution_etc_containers",
  "AdministratorDB::Schema::Result::Distribution",
  { "foreign.etc_container_id" => "self.container_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 distribution_root_containers

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Distribution>

=cut

__PACKAGE__->has_many(
  "distribution_root_containers",
  "AdministratorDB::Schema::Result::Distribution",
  { "foreign.root_container_id" => "self.container_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 hosts

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Host>

=cut

__PACKAGE__->has_many(
  "hosts",
  "AdministratorDB::Schema::Result::Host",
  { "foreign.etc_container_id" => "self.container_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 lvm_container

Type: might_have

Related object: L<AdministratorDB::Schema::Result::LvmContainer>

=cut

__PACKAGE__->might_have(
  "lvm_container",
  "AdministratorDB::Schema::Result::LvmContainer",
  { "foreign.lvm_container_id" => "self.container_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 systemimage_etc_containers

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Systemimage>

=cut

__PACKAGE__->has_many(
  "systemimage_etc_containers",
  "AdministratorDB::Schema::Result::Systemimage",
  { "foreign.etc_container_id" => "self.container_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 systemimage_root_containers

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Systemimage>

=cut

__PACKAGE__->has_many(
  "systemimage_root_containers",
  "AdministratorDB::Schema::Result::Systemimage",
  { "foreign.root_container_id" => "self.container_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-02-16 23:52:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NiYpacHUofFVeyByMFGrYg

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
  { "foreign.entity_id" => "self.container_id" },
  { cascade_copy => 0, cascade_delete => 1 }
);

1;
