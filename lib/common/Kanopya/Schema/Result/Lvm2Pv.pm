use utf8;
package Kanopya::Schema::Result::Lvm2Pv;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Lvm2Pv

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

=head1 TABLE: C<lvm2_pv>

=cut

__PACKAGE__->table("lvm2_pv");

=head1 ACCESSORS

=head2 lvm2_pv_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 lvm2_vg_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 lvm2_pv_name

  data_type: 'char'
  is_nullable: 0
  size: 64

=cut

__PACKAGE__->add_columns(
  "lvm2_pv_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "lvm2_vg_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "lvm2_pv_name",
  { data_type => "char", is_nullable => 0, size => 64 },
);

=head1 PRIMARY KEY

=over 4

=item * L</lvm2_pv_id>

=back

=cut

__PACKAGE__->set_primary_key("lvm2_pv_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<lvm2_UNIQUE>

=over 4

=item * L</lvm2_pv_name>

=item * L</lvm2_vg_id>

=back

=cut

__PACKAGE__->add_unique_constraint("lvm2_UNIQUE", ["lvm2_pv_name", "lvm2_vg_id"]);

=head1 RELATIONS

=head2 lvm2_vg

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Lvm2Vg>

=cut

__PACKAGE__->belongs_to(
  "lvm2_vg",
  "Kanopya::Schema::Result::Lvm2Vg",
  { lvm2_vg_id => "lvm2_vg_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GH39+2zbCrhn6+xHC+JOXA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
