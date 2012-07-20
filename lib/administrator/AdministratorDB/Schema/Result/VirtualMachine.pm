package AdministratorDB::Schema::Result::VirtualMachine;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::VirtualMachine

=cut

__PACKAGE__->table("virtual_machine");

=head1 ACCESSORS

=head2 virtual_machine_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 hypervisor_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 vnc_port

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "virtual_machine_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "hypervisor_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "vnc_port",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("virtual_machine_id");

=head1 RELATIONS

=head2 opennebula3_vm

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Opennebula3Vm>

=cut

__PACKAGE__->might_have(
  "opennebula3_vm",
  "AdministratorDB::Schema::Result::Opennebula3Vm",
  { "foreign.opennebula3_vm_id" => "self.virtual_machine_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 virtual_machine

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Host>

=cut

__PACKAGE__->belongs_to(
  "virtual_machine",
  "AdministratorDB::Schema::Result::Host",
  { host_id => "virtual_machine_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 hypervisor

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Hypervisor>

=cut

__PACKAGE__->belongs_to(
  "hypervisor",
  "AdministratorDB::Schema::Result::Hypervisor",
  { hypervisor_id => "hypervisor_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-07-18 11:47:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rgiChZaCIz62tfokLUN2CQ

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Host",
  { host_id => "virtual_machine_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
