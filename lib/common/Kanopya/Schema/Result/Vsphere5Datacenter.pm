use utf8;
package Kanopya::Schema::Result::Vsphere5Datacenter;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Vsphere5Datacenter

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

=head1 TABLE: C<vsphere5_datacenter>

=cut

__PACKAGE__->table("vsphere5_datacenter");

=head1 ACCESSORS

=head2 vsphere5_datacenter_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 vsphere5_datacenter_name

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 vsphere5_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "vsphere5_datacenter_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "vsphere5_datacenter_name",
  { data_type => "char", is_nullable => 0, size => 255 },
  "vsphere5_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</vsphere5_datacenter_id>

=back

=cut

__PACKAGE__->set_primary_key("vsphere5_datacenter_id");

=head1 RELATIONS

=head2 vsphere5

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Vsphere5>

=cut

__PACKAGE__->belongs_to(
  "vsphere5",
  "Kanopya::Schema::Result::Vsphere5",
  { vsphere5_id => "vsphere5_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 vsphere5_hypervisors

Type: has_many

Related object: L<Kanopya::Schema::Result::Vsphere5Hypervisor>

=cut

__PACKAGE__->has_many(
  "vsphere5_hypervisors",
  "Kanopya::Schema::Result::Vsphere5Hypervisor",
  {
    "foreign.vsphere5_datacenter_id" => "self.vsphere5_datacenter_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DWWbfeZQmnkp3DcWj5R2TQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
