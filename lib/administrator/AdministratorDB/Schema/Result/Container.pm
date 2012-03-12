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
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 service_provider

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "service_provider",
  "AdministratorDB::Schema::Result::ServiceProvider",
  { service_provider_id => "service_provider_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
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

=head2 file_container

Type: might_have

Related object: L<AdministratorDB::Schema::Result::FileContainer>

=cut

__PACKAGE__->might_have(
  "file_container",
  "AdministratorDB::Schema::Result::FileContainer",
  { "foreign.file_container_id" => "self.container_id" },
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

=head2 systemimages

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Systemimage>

=cut

__PACKAGE__->has_many(
  "systemimages",
  "AdministratorDB::Schema::Result::Systemimage",
  { "foreign.container_id" => "self.container_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-03-06 14:51:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3gMZVYm4fNmPRa4zMTAlAw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
