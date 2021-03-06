use utf8;
package Kanopya::Schema::Result::Opennebula3Hypervisor;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Opennebula3Hypervisor

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

=head1 TABLE: C<opennebula3_hypervisor>

=cut

__PACKAGE__->table("opennebula3_hypervisor");

=head1 ACCESSORS

=head2 opennebula3_hypervisor_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 onehost_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "opennebula3_hypervisor_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "onehost_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</opennebula3_hypervisor_id>

=back

=cut

__PACKAGE__->set_primary_key("opennebula3_hypervisor_id");

=head1 RELATIONS

=head2 opennebula3_hypervisor

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Hypervisor>

=cut

__PACKAGE__->belongs_to(
  "opennebula3_hypervisor",
  "Kanopya::Schema::Result::Hypervisor",
  { hypervisor_id => "opennebula3_hypervisor_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 opennebula3_kvm_hypervisor

Type: might_have

Related object: L<Kanopya::Schema::Result::Opennebula3KvmHypervisor>

=cut

__PACKAGE__->might_have(
  "opennebula3_kvm_hypervisor",
  "Kanopya::Schema::Result::Opennebula3KvmHypervisor",
  {
    "foreign.opennebula3_kvm_hypervisor_id" => "self.opennebula3_hypervisor_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 opennebula3_xen_hypervisor

Type: might_have

Related object: L<Kanopya::Schema::Result::Opennebula3XenHypervisor>

=cut

__PACKAGE__->might_have(
  "opennebula3_xen_hypervisor",
  "Kanopya::Schema::Result::Opennebula3XenHypervisor",
  {
    "foreign.opennebula3_xen_hypervisor_id" => "self.opennebula3_hypervisor_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-08-26 16:00:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hXrbde4rp9/1W76VMneQ6g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
