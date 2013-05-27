use utf8;
package AdministratorDB::Schema::Result::Tag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Tag

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

=head1 TABLE: C<tag>

=cut

__PACKAGE__->table("tag");

=head1 ACCESSORS

=head2 tag_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 tag

  data_type: 'char'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "tag_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "tag",
  { data_type => "char", is_nullable => 0, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</tag_id>

=back

=cut

__PACKAGE__->set_primary_key("tag_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<tag>

=over 4

=item * L</tag>

=back

=cut

__PACKAGE__->add_unique_constraint("tag", ["tag"]);

=head1 RELATIONS

=head2 entity_tags

Type: has_many

Related object: L<AdministratorDB::Schema::Result::EntityTag>

=cut

__PACKAGE__->has_many(
  "entity_tags",
  "AdministratorDB::Schema::Result::EntityTag",
  { "foreign.tag_id" => "self.tag_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 tag

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "tag",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "tag_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 entities

Type: many_to_many

Composing rels: L</entity_tags> -> entity

=cut

__PACKAGE__->many_to_many("entities", "entity_tags", "entity");


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-23 18:16:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Sp/zMF333N7h/q4yPVpmMw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
