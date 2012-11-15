use utf8;
package AdministratorDB::Schema::Result::Gp;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Gp

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

=head1 TABLE: C<gp>

=cut

__PACKAGE__->table("gp");

=head1 ACCESSORS

=head2 gp_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 gp_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 gp_type

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 gp_desc

  data_type: 'char'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "gp_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "gp_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "gp_type",
  { data_type => "char", is_nullable => 0, size => 32 },
  "gp_desc",
  { data_type => "char", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</gp_id>

=back

=cut

__PACKAGE__->set_primary_key("gp_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<gp_name>

=over 4

=item * L</gp_name>

=back

=cut

__PACKAGE__->add_unique_constraint("gp_name", ["gp_name"]);

=head1 RELATIONS

=head2 gp

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "gp",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "gp_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 ingroups

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Ingroup>

=cut

__PACKAGE__->has_many(
  "ingroups",
  "AdministratorDB::Schema::Result::Ingroup",
  { "foreign.gp_id" => "self.gp_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 profile_gps

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ProfileGp>

=cut

__PACKAGE__->has_many(
  "profile_gps",
  "AdministratorDB::Schema::Result::ProfileGp",
  { "foreign.gp_id" => "self.gp_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 entities

Type: many_to_many

Composing rels: L</ingroups> -> entity

=cut

__PACKAGE__->many_to_many("entities", "ingroups", "entity");

=head2 profiles

Type: many_to_many

Composing rels: L</profile_gps> -> profile

=cut

__PACKAGE__->many_to_many("profiles", "profile_gps", "profile");


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-11-09 17:14:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:O26rqz/JqUFbubAjc/9HWQ

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "gp_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
