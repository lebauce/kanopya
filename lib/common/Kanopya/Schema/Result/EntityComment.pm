use utf8;
package Kanopya::Schema::Result::EntityComment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::EntityComment

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

=head1 TABLE: C<entity_comment>

=cut

__PACKAGE__->table("entity_comment");

=head1 ACCESSORS

=head2 entity_comment_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 entity_comment

  data_type: 'char'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "entity_comment_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "entity_comment",
  { data_type => "char", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</entity_comment_id>

=back

=cut

__PACKAGE__->set_primary_key("entity_comment_id");

=head1 RELATIONS

=head2 entities

Type: has_many

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->has_many(
  "entities",
  "Kanopya::Schema::Result::Entity",
  { "foreign.entity_comment_id" => "self.entity_comment_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UG8gSuERQjx30H5WgcB5OQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
