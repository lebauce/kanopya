use utf8;
package AdministratorDB::Schema::Result::Xen;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Xen

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

=head1 TABLE: C<xen>

=cut

__PACKAGE__->table("xen");

=head1 ACCESSORS

=head2 xen_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "xen_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</xen_id>

=back

=cut

__PACKAGE__->set_primary_key("xen_id");

=head1 RELATIONS

=head2 xen

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Vmm>

=cut

__PACKAGE__->belongs_to(
  "xen",
  "AdministratorDB::Schema::Result::Vmm",
  { vmm_id => "xen_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-11-21 19:25:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9UYvTSZDtvIXbeslfyZrJw

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Vmm",
    { "foreign.vmm_id" => "self.xen_id" },
    { cascade_copy => 0, cascade_delete => 1 });


1;
