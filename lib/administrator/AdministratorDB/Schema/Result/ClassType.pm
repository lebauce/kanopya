use utf8;
package AdministratorDB::Schema::Result::ClassType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::ClassType

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

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

=head2 component_types

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ComponentType>

=cut

__PACKAGE__->has_many(
  "component_types",
  "AdministratorDB::Schema::Result::ComponentType",
  { "foreign.component_class_id" => "self.class_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 entities

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->has_many(
  "entities",
  "AdministratorDB::Schema::Result::Entity",
  { "foreign.class_type_id" => "self.class_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-10-31 01:59:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3zuTM2fmvsXOLJn7xz8Kpw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
