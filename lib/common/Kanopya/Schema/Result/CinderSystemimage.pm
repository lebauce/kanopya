use utf8;
package Kanopya::Schema::Result::CinderSystemimage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::CinderSystemimage

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

=head1 TABLE: C<cinder_systemimage>

=cut

__PACKAGE__->table("cinder_systemimage");

=head1 ACCESSORS

=head2 cinder_systemimage_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 image_uuid

  data_type: 'char'
  is_nullable: 1
  size: 64

=head2 volume_uuid

  data_type: 'char'
  is_nullable: 1
  size: 64

=cut

__PACKAGE__->add_columns(
  "cinder_systemimage_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "image_uuid",
  { data_type => "char", is_nullable => 1, size => 64 },
  "volume_uuid",
  { data_type => "char", is_nullable => 1, size => 64 },
);

=head1 PRIMARY KEY

=over 4

=item * L</cinder_systemimage_id>

=back

=cut

__PACKAGE__->set_primary_key("cinder_systemimage_id");

=head1 RELATIONS

=head2 cinder_systemimage

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Systemimage>

=cut

__PACKAGE__->belongs_to(
  "cinder_systemimage",
  "Kanopya::Schema::Result::Systemimage",
  { systemimage_id => "cinder_systemimage_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-09-18 16:54:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:a/zQz3QEu8d5qckO5X5/sg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
