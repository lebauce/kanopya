package AdministratorDB::Schema::Result::Masterimage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Masterimage

=cut

__PACKAGE__->table("masterimage");

=head1 ACCESSORS

=head2 masterimage_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 masterimage_name

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 masterimage_file

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 masterimage_desc

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 masterimage_os

  data_type: 'char'
  is_nullable: 1
  size: 64

=head2 masterimage_size

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "masterimage_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "masterimage_name",
  { data_type => "char", is_nullable => 0, size => 64 },
  "masterimage_file",
  { data_type => "char", is_nullable => 0, size => 255 },
  "masterimage_desc",
  { data_type => "char", is_nullable => 1, size => 255 },
  "masterimage_os",
  { data_type => "char", is_nullable => 1, size => 64 },
  "masterimage_size",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("masterimage_id");

=head1 RELATIONS

=head2 clusters

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Cluster>

=cut

__PACKAGE__->has_many(
  "clusters",
  "AdministratorDB::Schema::Result::Cluster",
  { "foreign.masterimage_id" => "self.masterimage_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 components_provided

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ComponentProvided>

=cut

__PACKAGE__->has_many(
  "components_provided",
  "AdministratorDB::Schema::Result::ComponentProvided",
  { "foreign.masterimage_id" => "self.masterimage_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 masterimage

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "masterimage",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "masterimage_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-03-28 16:32:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xVN5wsSJk4mBdG50/e0C1w
__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
        { "foreign.entity_id" => "self.masterimage_id" },
        { cascade_copy => 0, cascade_delete => 1 }
);


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
