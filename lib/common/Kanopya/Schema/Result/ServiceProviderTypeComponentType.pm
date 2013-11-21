use utf8;
package Kanopya::Schema::Result::ServiceProviderTypeComponentType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::ServiceProviderTypeComponentType

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

=head1 TABLE: C<service_provider_type_component_type>

=cut

__PACKAGE__->table("service_provider_type_component_type");

=head1 ACCESSORS

=head2 service_provider_type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 component_type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "service_provider_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "component_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</service_provider_type_id>

=item * L</component_type_id>

=back

=cut

__PACKAGE__->set_primary_key("service_provider_type_id", "component_type_id");

=head1 RELATIONS

=head2 component_type

Type: belongs_to

Related object: L<Kanopya::Schema::Result::ComponentType>

=cut

__PACKAGE__->belongs_to(
  "component_type",
  "Kanopya::Schema::Result::ComponentType",
  { component_type_id => "component_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 service_provider_type

Type: belongs_to

Related object: L<Kanopya::Schema::Result::ServiceProviderType>

=cut

__PACKAGE__->belongs_to(
  "service_provider_type",
  "Kanopya::Schema::Result::ServiceProviderType",
  { service_provider_type_id => "service_provider_type_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GmzHk0x8ezVKAXlg6i75lw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
