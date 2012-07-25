package AdministratorDB::Schema::Result::Hypervisor;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Hypervisor

=cut

__PACKAGE__->table("hypervisor");

=head1 ACCESSORS

=head2 hypervisor_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "hypervisor_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("hypervisor_id");

=head1 RELATIONS

=head2 hypervisor

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Host>

=cut

__PACKAGE__->belongs_to(
  "hypervisor",
  "AdministratorDB::Schema::Result::Host",
  { host_id => "hypervisor_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 opennebula3_hypervisor

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Opennebula3Hypervisor>

=cut

__PACKAGE__->might_have(
  "opennebula3_hypervisor",
  "AdministratorDB::Schema::Result::Opennebula3Hypervisor",
  { "foreign.opennebula3_hypervisor_id" => "self.hypervisor_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 virtual_machines

Type: has_many

Related object: L<AdministratorDB::Schema::Result::VirtualMachine>

=cut

__PACKAGE__->has_many(
  "virtual_machines",
  "AdministratorDB::Schema::Result::VirtualMachine",
  { "foreign.hypervisor_id" => "self.hypervisor_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-07-19 15:18:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SWFjJqoiR3bSfY2FNRirmA

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Host",
  { host_id => "hypervisor_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
