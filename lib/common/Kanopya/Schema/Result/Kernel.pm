use utf8;
package Kanopya::Schema::Result::Kernel;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Kernel

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

=head1 TABLE: C<kernel>

=cut

__PACKAGE__->table("kernel");

=head1 ACCESSORS

=head2 kernel_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 kernel_name

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 kernel_version

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 kernel_desc

  data_type: 'char'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "kernel_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "kernel_name",
  { data_type => "char", is_nullable => 0, size => 64 },
  "kernel_version",
  { data_type => "char", is_nullable => 0, size => 32 },
  "kernel_desc",
  { data_type => "char", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</kernel_id>

=back

=cut

__PACKAGE__->set_primary_key("kernel_id");

=head1 RELATIONS

=head2 clusters

Type: has_many

Related object: L<Kanopya::Schema::Result::Cluster>

=cut

__PACKAGE__->has_many(
  "clusters",
  "Kanopya::Schema::Result::Cluster",
  { "foreign.kernel_id" => "self.kernel_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 hosts

Type: has_many

Related object: L<Kanopya::Schema::Result::Host>

=cut

__PACKAGE__->has_many(
  "hosts",
  "Kanopya::Schema::Result::Host",
  { "foreign.kernel_id" => "self.kernel_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 kernel

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "kernel",
  "Kanopya::Schema::Result::Entity",
  { entity_id => "kernel_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 masterimages

Type: has_many

Related object: L<Kanopya::Schema::Result::Masterimage>

=cut

__PACKAGE__->has_many(
  "masterimages",
  "Kanopya::Schema::Result::Masterimage",
  { "foreign.masterimage_defaultkernel_id" => "self.kernel_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6JBd/P6MRwTJy3YI47MJsw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
