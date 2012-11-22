use utf8;
package AdministratorDB::Schema::Result::Vmm;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Vmm

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
  is_nullable: 0

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
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</vmm_id>

=back

=cut

__PACKAGE__->set_primary_key("vmm_id");

=head1 RELATIONS

=head2 iaas

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "iaas",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "iaas_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 kvm

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Kvm>

=cut

__PACKAGE__->might_have(
  "kvm",
  "AdministratorDB::Schema::Result::Kvm",
  { "foreign.kvm_id" => "self.vmm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vmm

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "vmm",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "vmm_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 xen

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Xen>

=cut

__PACKAGE__->might_have(
  "xen",
  "AdministratorDB::Schema::Result::Xen",
  { "foreign.xen_id" => "self.vmm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-11-21 19:20:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EBUob6FF/iAcYOVZVuGVKw

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Component",
    { "foreign.component_id" => "self.vmm_id" },
    { cascade_copy => 0, cascade_delete => 1 });

1;
