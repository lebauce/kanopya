use utf8;
package AdministratorDB::Schema::Result::Kvm;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Kvm

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

=head1 TABLE: C<kvm>

=cut

__PACKAGE__->table("kvm");

=head1 ACCESSORS

=head2 kvm_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "kvm_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</kvm_id>

=back

=cut

__PACKAGE__->set_primary_key("kvm_id");

=head1 RELATIONS

=head2 kvm

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Vmm>

=cut

__PACKAGE__->belongs_to(
  "kvm",
  "AdministratorDB::Schema::Result::Vmm",
  { vmm_id => "kvm_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-11-21 19:20:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OrgTKuSWi/dgT4g9v3u2jA

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Vmm",
    { "foreign.vmm_id" => "self.kvm_id" },
    { cascade_copy => 0, cascade_delete => 1 });

1;
