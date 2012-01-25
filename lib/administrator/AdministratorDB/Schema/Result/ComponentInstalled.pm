package AdministratorDB::Schema::Result::ComponentInstalled;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::ComponentInstalled

=cut

__PACKAGE__->table("component_installed");

=head1 ACCESSORS

=head2 component_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 systemimage_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "component_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "systemimage_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("component_id", "systemimage_id");

=head1 RELATIONS

=head2 component

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "component",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "component_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 systemimage

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Systemimage>

=cut

__PACKAGE__->belongs_to(
  "systemimage",
  "AdministratorDB::Schema::Result::Systemimage",
  { systemimage_id => "systemimage_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-25 14:17:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4694QUHd2EG6CuDyVHia3w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
