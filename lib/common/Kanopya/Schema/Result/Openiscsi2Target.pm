use utf8;
package Kanopya::Schema::Result::Openiscsi2Target;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Openiscsi2Target

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

=head1 TABLE: C<openiscsi2_target>

=cut

__PACKAGE__->table("openiscsi2_target");

=head1 ACCESSORS

=head2 openiscsi2_target_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 openiscsi2_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 openiscsi2_target

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 openiscsi2_server

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 openiscsi2_port

  data_type: 'integer'
  is_nullable: 1

=head2 openiscsi2_mount_point

  data_type: 'char'
  is_nullable: 1
  size: 64

=head2 openiscsi2_mount_options

  data_type: 'char'
  is_nullable: 1
  size: 64

=head2 openiscsi2_filesystem

  data_type: 'char'
  is_nullable: 1
  size: 32

=cut

__PACKAGE__->add_columns(
  "openiscsi2_target_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "openiscsi2_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "openiscsi2_target",
  { data_type => "char", is_nullable => 0, size => 64 },
  "openiscsi2_server",
  { data_type => "char", is_nullable => 0, size => 32 },
  "openiscsi2_port",
  { data_type => "integer", is_nullable => 1 },
  "openiscsi2_mount_point",
  { data_type => "char", is_nullable => 1, size => 64 },
  "openiscsi2_mount_options",
  { data_type => "char", is_nullable => 1, size => 64 },
  "openiscsi2_filesystem",
  { data_type => "char", is_nullable => 1, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</openiscsi2_target_id>

=back

=cut

__PACKAGE__->set_primary_key("openiscsi2_target_id");

=head1 RELATIONS

=head2 openiscsi2

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Openiscsi2>

=cut

__PACKAGE__->belongs_to(
  "openiscsi2",
  "Kanopya::Schema::Result::Openiscsi2",
  { openiscsi2_id => "openiscsi2_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EddMvqWUkbXIzHZXuBR6oA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
