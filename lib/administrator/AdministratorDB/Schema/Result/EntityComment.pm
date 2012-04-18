package AdministratorDB::Schema::Result::EntityComment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::EntityComment

=cut

__PACKAGE__->table("entity_comment");

=head1 ACCESSORS

=head2 entity_comment_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 entity_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 entity_comment

  data_type: 'char'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "entity_comment_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "entity_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "entity_comment",
  { data_type => "char", is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("entity_comment_id");

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


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-04-17 14:12:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/C+tmsBQMn/6f88FDwT49w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
