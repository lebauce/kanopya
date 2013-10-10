use utf8;
package AdministratorDB::Schema::Result::Virtualization;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Virtualization

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

=head1 TABLE: C<virtualization>

=cut

__PACKAGE__->table("virtualization");

=head1 ACCESSORS

=head2 virtualization_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 overcommitment_cpu_factor

  data_type: 'double precision'
  default_value: 1
  extra: {unsigned => 1}
  is_nullable: 0

=head2 overcommitment_memory_factor

  data_type: 'double precision'
  default_value: 1
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "virtualization_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "overcommitment_cpu_factor",
  {
    data_type => "double precision",
    default_value => 1,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "overcommitment_memory_factor",
  {
    data_type => "double precision",
    default_value => 1,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</virtualization_id>

=back

=cut

__PACKAGE__->set_primary_key("virtualization_id");

=head1 RELATIONS

=head2 nova_controller

Type: might_have

Related object: L<AdministratorDB::Schema::Result::NovaController>

=cut

__PACKAGE__->might_have(
  "nova_controller",
  "AdministratorDB::Schema::Result::NovaController",
  { "foreign.nova_controller_id" => "self.virtualization_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 opennebula3

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Opennebula3>

=cut

__PACKAGE__->might_have(
  "opennebula3",
  "AdministratorDB::Schema::Result::Opennebula3",
  { "foreign.opennebula3_id" => "self.virtualization_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 repositories

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Repository>

=cut

__PACKAGE__->has_many(
  "repositories",
  "AdministratorDB::Schema::Result::Repository",
  { "foreign.virtualization_id" => "self.virtualization_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 virtualization

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "virtualization",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "virtualization_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 vmms

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Vmm>

=cut

__PACKAGE__->has_many(
  "vmms",
  "AdministratorDB::Schema::Result::Vmm",
  { "foreign.iaas_id" => "self.virtualization_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vsphere5

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Vsphere5>

=cut

__PACKAGE__->might_have(
  "vsphere5",
  "AdministratorDB::Schema::Result::Vsphere5",
  { "foreign.vsphere5_id" => "self.virtualization_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-06-13 02:55:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:m9gZaD+kIARsZNKIwlbcQg


__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "virtualization_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
