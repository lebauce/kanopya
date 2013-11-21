use utf8;
package Kanopya::Schema::Result::Fileimagemanager0;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Fileimagemanager0

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

=head1 TABLE: C<fileimagemanager0>

=cut

__PACKAGE__->table("fileimagemanager0");

=head1 ACCESSORS

=head2 fileimagemanager0_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 image_type

  data_type: 'char'
  default_value: 'img'
  is_nullable: 0
  size: 128

=cut

__PACKAGE__->add_columns(
  "fileimagemanager0_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "image_type",
  { data_type => "char", default_value => "img", is_nullable => 0, size => 128 },
);

=head1 PRIMARY KEY

=over 4

=item * L</fileimagemanager0_id>

=back

=cut

__PACKAGE__->set_primary_key("fileimagemanager0_id");

=head1 RELATIONS

=head2 fileimagemanager0

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "fileimagemanager0",
  "Kanopya::Schema::Result::Component",
  { component_id => "fileimagemanager0_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:drgn3KrtFkQaXlkTFMnTQQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
