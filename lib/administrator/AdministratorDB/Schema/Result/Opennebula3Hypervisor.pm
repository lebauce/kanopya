package AdministratorDB::Schema::Result::Opennebula3Hypervisor;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Opennebula3Hypervisor

=cut

__PACKAGE__->table("opennebula3_hypervisor");

=head1 ACCESSORS

=head2 opennebula3_hypervisor_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 opennebula3_id

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
  "opennebula3_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "onehost_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("opennebula3_hypervisor_id");

=head1 RELATIONS

=head2 opennebula3_hypervisor

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Hypervisor>

=cut

__PACKAGE__->belongs_to(
  "opennebula3_hypervisor",
  "AdministratorDB::Schema::Result::Hypervisor",
  { hypervisor_id => "opennebula3_hypervisor_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 opennebula3

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Opennebula3>

=cut

__PACKAGE__->belongs_to(
  "opennebula3",
  "AdministratorDB::Schema::Result::Opennebula3",
  { opennebula3_id => "opennebula3_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 opennebula3_kvm_hypervisor

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Opennebula3KvmHypervisor>

=cut

__PACKAGE__->might_have(
  "opennebula3_kvm_hypervisor",
  "AdministratorDB::Schema::Result::Opennebula3KvmHypervisor",
  {
    "foreign.opennebula3_kvm_hypervisor_id" => "self.opennebula3_hypervisor_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 opennebula3_xen_hypervisor

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Opennebula3XenHypervisor>

=cut

__PACKAGE__->might_have(
  "opennebula3_xen_hypervisor",
  "AdministratorDB::Schema::Result::Opennebula3XenHypervisor",
  {
    "foreign.opennebula3_xen_hypervisor_id" => "self.opennebula3_hypervisor_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-08-06 17:35:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0IyDdCOONg0FRWqDUEg+lg

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Hypervisor",
  { hypervisor_id => "opennebula3_hypervisor_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
