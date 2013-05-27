use utf8;
package AdministratorDB::Schema::Result::EntityTag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::EntityTag

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

=head1 TABLE: C<entity_tag>

=cut

__PACKAGE__->table("entity_tag");

=head1 ACCESSORS

=head2 entity_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 tag_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "entity_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "tag_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</entity_id>

=item * L</tag_id>

=back

=cut

__PACKAGE__->set_primary_key("entity_id", "tag_id");

=head1 RELATIONS

=head2 entity

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "entity",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "entity_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 tag

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Tag>

=cut

__PACKAGE__->belongs_to(
  "tag",
  "AdministratorDB::Schema::Result::Tag",
  { tag_id => "tag_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-23 18:20:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:liExortap+r34pYJfKC3bA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
