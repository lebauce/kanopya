package AdministratorDB::Schema::Result::Ingroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Ingroup

=cut

__PACKAGE__->table("ingroups");

=head1 ACCESSORS

=head2 gp_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 entity_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "gp_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "entity_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("gp_id", "entity_id");

=head1 RELATIONS

=head2 entity

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "entity",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "entity_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 gp

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Gp>

=cut

__PACKAGE__->belongs_to(
  "gp",
  "AdministratorDB::Schema::Result::Gp",
  { gp_id => "gp_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-27 08:08:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9LHDeNsLIiKZqIy0qW7zww


# You can replace this text with custom content, and it will be preserved on regeneration
1;
