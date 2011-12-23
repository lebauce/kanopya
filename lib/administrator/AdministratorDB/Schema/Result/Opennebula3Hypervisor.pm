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

=head2 opennebula3_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 hypervisor_host_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 hypervisor_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "opennebula3_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "hypervisor_host_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "hypervisor_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("hypervisor_host_id");

=head1 RELATIONS

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

=head2 hypervisor_host

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Host>

=cut

__PACKAGE__->belongs_to(
  "hypervisor_host",
  "AdministratorDB::Schema::Result::Host",
  { host_id => "hypervisor_host_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 opennebula3_vms

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Opennebula3Vm>

=cut

__PACKAGE__->has_many(
  "opennebula3_vms",
  "AdministratorDB::Schema::Result::Opennebula3Vm",
  { "foreign.hypervisor_host_id" => "self.hypervisor_host_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-12-23 11:19:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YoSpNCHnO97aYxQOo6vIcg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
