use utf8;
package Kanopya::Schema::Result::LvmContainer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::LvmContainer

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

=head1 TABLE: C<lvm_container>

=cut

__PACKAGE__->table("lvm_container");

=head1 ACCESSORS

=head2 lvm_container_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 lv_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "lvm_container_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "lv_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</lvm_container_id>

=back

=cut

__PACKAGE__->set_primary_key("lvm_container_id");

=head1 RELATIONS

=head2 lvm_container

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Container>

=cut

__PACKAGE__->belongs_to(
  "lvm_container",
  "Kanopya::Schema::Result::Container",
  { container_id => "lvm_container_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3wI0ybc9H7VbyWRzGpESdA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
