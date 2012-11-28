use utf8;
package AdministratorDB::Schema::Result::Iscsi;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Iscsi

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

=head1 TABLE: C<iscsi>

=cut

__PACKAGE__->table("iscsi");

=head1 ACCESSORS

=head2 iscsi_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "iscsi_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</iscsi_id>

=back

=cut

__PACKAGE__->set_primary_key("iscsi_id");

=head1 RELATIONS

=head2 iscsi

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "iscsi",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "iscsi_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 iscsi_portals

Type: has_many

Related object: L<AdministratorDB::Schema::Result::IscsiPortal>

=cut

__PACKAGE__->has_many(
  "iscsi_portals",
  "AdministratorDB::Schema::Result::IscsiPortal",
  { "foreign.iscsi_id" => "self.iscsi_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 iscsitarget1

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Iscsitarget1>

=cut

__PACKAGE__->might_have(
  "iscsitarget1",
  "AdministratorDB::Schema::Result::Iscsitarget1",
  { "foreign.iscsitarget1_id" => "self.iscsi_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-11-27 16:08:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5M1HdoiVDipWEhXIA7GQ0A

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "iscsi_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
