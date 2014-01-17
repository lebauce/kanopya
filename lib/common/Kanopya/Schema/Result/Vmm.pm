use utf8;
package Kanopya::Schema::Result::Vmm;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Vmm

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

=head1 TABLE: C<vmm>

=cut

__PACKAGE__->table("vmm");

=head1 ACCESSORS

=head2 vmm_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 iaas_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "vmm_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "iaas_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</vmm_id>

=back

=cut

__PACKAGE__->set_primary_key("vmm_id");

=head1 RELATIONS

=head2 iaa

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Virtualization>

=cut

__PACKAGE__->belongs_to(
  "iaa",
  "Kanopya::Schema::Result::Virtualization",
  { virtualization_id => "iaas_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 kvm

Type: might_have

Related object: L<Kanopya::Schema::Result::Kvm>

=cut

__PACKAGE__->might_have(
  "kvm",
  "Kanopya::Schema::Result::Kvm",
  { "foreign.kvm_id" => "self.vmm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nova_compute

Type: might_have

Related object: L<Kanopya::Schema::Result::NovaCompute>

=cut

__PACKAGE__->might_have(
  "nova_compute",
  "Kanopya::Schema::Result::NovaCompute",
  { "foreign.nova_compute_id" => "self.vmm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vmm

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "vmm",
  "Kanopya::Schema::Result::Component",
  { component_id => "vmm_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 xen

Type: might_have

Related object: L<Kanopya::Schema::Result::Xen>

=cut

__PACKAGE__->might_have(
  "xen",
  "Kanopya::Schema::Result::Xen",
  { "foreign.xen_id" => "self.vmm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XBtERL2jCeFdVCD+aP1qRg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
