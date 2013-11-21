use utf8;
package Kanopya::Schema::Result::NetappLun;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::NetappLun

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

=head1 TABLE: C<netapp_lun>

=cut

__PACKAGE__->table("netapp_lun");

=head1 ACCESSORS

=head2 lun_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 volume_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "lun_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "volume_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</lun_id>

=back

=cut

__PACKAGE__->set_primary_key("lun_id");

=head1 RELATIONS

=head2 lun

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Container>

=cut

__PACKAGE__->belongs_to(
  "lun",
  "Kanopya::Schema::Result::Container",
  { container_id => "lun_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 volume

Type: belongs_to

Related object: L<Kanopya::Schema::Result::NetappVolume>

=cut

__PACKAGE__->belongs_to(
  "volume",
  "Kanopya::Schema::Result::NetappVolume",
  { volume_id => "volume_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TACIQ0o+dmi92oGAb2qROA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
