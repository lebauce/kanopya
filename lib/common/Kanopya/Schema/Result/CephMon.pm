use utf8;
package Kanopya::Schema::Result::CephMon;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::CephMon

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

=head1 TABLE: C<ceph_mon>

=cut

__PACKAGE__->table("ceph_mon");

=head1 ACCESSORS

=head2 ceph_mon_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 ceph_mon_secret

  data_type: 'char'
  is_nullable: 1
  size: 64

=head2 ceph_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "ceph_mon_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "ceph_mon_secret",
  { data_type => "char", is_nullable => 1, size => 64 },
  "ceph_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</ceph_mon_id>

=back

=cut

__PACKAGE__->set_primary_key("ceph_mon_id");

=head1 RELATIONS

=head2 ceph

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Ceph>

=cut

__PACKAGE__->belongs_to(
  "ceph",
  "Kanopya::Schema::Result::Ceph",
  { ceph_id => "ceph_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 ceph_mon

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "ceph_mon",
  "Kanopya::Schema::Result::Component",
  { component_id => "ceph_mon_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JAv/krNgbsw9ScKCIGVCrQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
