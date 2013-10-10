use utf8;
package AdministratorDB::Schema::Result::Iscsitarget1;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Iscsitarget1

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

=head1 TABLE: C<iscsitarget1>

=cut

__PACKAGE__->table("iscsitarget1");

=head1 ACCESSORS

=head2 iscsitarget1_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "iscsitarget1_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</iscsitarget1_id>

=back

=cut

__PACKAGE__->set_primary_key("iscsitarget1_id");

=head1 RELATIONS

=head2 iscsitarget1

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Iscsi>

=cut

__PACKAGE__->belongs_to(
  "iscsitarget1",
  "AdministratorDB::Schema::Result::Iscsi",
  { iscsi_id => "iscsitarget1_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-11-27 16:08:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:U3JINZwkFREf1uhZ4jL8mA

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Iscsi",
  { iscsi_id => "iscsitarget1_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);
1;
