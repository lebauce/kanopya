use utf8;
package AdministratorDB::Schema::Result::ManagerCategory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::ManagerCategory

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

=head1 TABLE: C<manager_category>

=cut

__PACKAGE__->table("manager_category");

=head1 ACCESSORS

=head2 manager_category_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "manager_category_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</manager_category_id>

=back

=cut

__PACKAGE__->set_primary_key("manager_category_id");

=head1 RELATIONS

=head2 manager_category

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ComponentCategory>

=cut

__PACKAGE__->belongs_to(
  "manager_category",
  "AdministratorDB::Schema::Result::ComponentCategory",
  { component_category_id => "manager_category_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 service_provider_managers

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ServiceProviderManager>

=cut

__PACKAGE__->has_many(
  "service_provider_managers",
  "AdministratorDB::Schema::Result::ServiceProviderManager",
  { "foreign.manager_category_id" => "self.manager_category_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2013-01-31 11:35:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XZ/4V0sP1gkKtEDs4mOWHQ

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::ComponentCategory",
  { component_category_id => "manager_category_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
