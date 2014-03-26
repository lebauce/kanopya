use utf8;
package Kanopya::Schema::Result::ClassType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::ClassType

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

=head1 TABLE: C<class_type>

=cut

__PACKAGE__->table("class_type");

=head1 ACCESSORS

=head2 class_type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 class_type

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "class_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "class_type",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</class_type_id>

=back

=cut

__PACKAGE__->set_primary_key("class_type_id");

=head1 RELATIONS

=head2 component_type

Type: might_have

Related object: L<Kanopya::Schema::Result::ComponentType>

=cut

__PACKAGE__->might_have(
  "component_type",
  "Kanopya::Schema::Result::ComponentType",
  { "foreign.component_type_id" => "self.class_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 entities

Type: has_many

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->has_many(
  "entities",
  "Kanopya::Schema::Result::Entity",
  { "foreign.class_type_id" => "self.class_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_provider_type

Type: might_have

Related object: L<Kanopya::Schema::Result::ServiceProviderType>

=cut

__PACKAGE__->might_have(
  "service_provider_type",
  "Kanopya::Schema::Result::ServiceProviderType",
  { "foreign.service_provider_type_id" => "self.class_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-03-24 16:34:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+Np+E2EIixUlYwr14fpl6Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
