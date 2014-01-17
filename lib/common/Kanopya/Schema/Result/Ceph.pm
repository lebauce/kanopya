use utf8;
package Kanopya::Schema::Result::Ceph;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Ceph

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

=head1 TABLE: C<ceph>

=cut

__PACKAGE__->table("ceph");

=head1 ACCESSORS

=head2 ceph_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 ceph_fsid

  data_type: 'char'
  is_nullable: 1
  size: 64

=cut

__PACKAGE__->add_columns(
  "ceph_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "ceph_fsid",
  { data_type => "char", is_nullable => 1, size => 64 },
);

=head1 PRIMARY KEY

=over 4

=item * L</ceph_id>

=back

=cut

__PACKAGE__->set_primary_key("ceph_id");

=head1 RELATIONS

=head2 ceph

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "ceph",
  "Kanopya::Schema::Result::Component",
  { component_id => "ceph_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 ceph_mons

Type: has_many

Related object: L<Kanopya::Schema::Result::CephMon>

=cut

__PACKAGE__->has_many(
  "ceph_mons",
  "Kanopya::Schema::Result::CephMon",
  { "foreign.ceph_id" => "self.ceph_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ceph_osds

Type: has_many

Related object: L<Kanopya::Schema::Result::CephOsd>

=cut

__PACKAGE__->has_many(
  "ceph_osds",
  "Kanopya::Schema::Result::CephOsd",
  { "foreign.ceph_id" => "self.ceph_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3gO8Iq2m2pGpULzJAQXDSg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
