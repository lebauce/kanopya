use utf8;
package AdministratorDB::Schema::Result::Openssh5;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Openssh5

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

=head1 TABLE: C<openssh5>

=cut

__PACKAGE__->table("openssh5");

=head1 ACCESSORS

=head2 openssh5_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "openssh5_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</openssh5_id>

=back

=cut

__PACKAGE__->set_primary_key("openssh5_id");

=head1 RELATIONS

=head2 openssh5

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "openssh5",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "openssh5_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-11 14:47:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZtyIF7gPthRUHr3wwxeQ4A
__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Component",
    { "foreign.component_id" => "self.openssh5_id" },
    { cascade_copy => 0, cascade_delete => 1 });
1;
