package AdministratorDB::Schema::Result::Distribution;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Distribution

=cut

__PACKAGE__->table("distribution");

=head1 ACCESSORS

=head2 distribution_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 distribution_name

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 distribution_version

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 distribution_desc

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 etc_container_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 root_container_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "distribution_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "distribution_name",
  { data_type => "char", is_nullable => 0, size => 64 },
  "distribution_version",
  { data_type => "char", is_nullable => 0, size => 32 },
  "distribution_desc",
  { data_type => "char", is_nullable => 1, size => 255 },
  "etc_container_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "root_container_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("distribution_id");

=head1 RELATIONS

=head2 components_provided

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ComponentProvided>

=cut

__PACKAGE__->has_many(
  "components_provided",
  "AdministratorDB::Schema::Result::ComponentProvided",
  { "foreign.distribution_id" => "self.distribution_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 distribution

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "distribution",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "distribution_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 etc_container

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Container>

=cut

__PACKAGE__->belongs_to(
  "etc_container",
  "AdministratorDB::Schema::Result::Container",
  { container_id => "etc_container_id" },
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 root_container

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Container>

=cut

__PACKAGE__->belongs_to(
  "root_container",
  "AdministratorDB::Schema::Result::Container",
  { container_id => "root_container_id" },
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 systemimages

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Systemimage>

=cut

__PACKAGE__->has_many(
  "systemimages",
  "AdministratorDB::Schema::Result::Systemimage",
  { "foreign.distribution_id" => "self.distribution_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-02-07 11:41:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:i6aGCq+xbhpgxm6BKLiR2Q


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
  { "foreign.entity_id" => "self.distribution_id" },
  { cascade_copy => 0, cascade_delete => 1 });

1;
