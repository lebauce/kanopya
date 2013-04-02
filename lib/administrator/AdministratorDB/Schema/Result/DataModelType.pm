use utf8;
package AdministratorDB::Schema::Result::DataModelType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::DataModelType

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

=head1 TABLE: C<data_model_type>

=cut

__PACKAGE__->table("data_model_type");

=head1 ACCESSORS

=head2 data_model_type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 data_model_type_label

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 data_model_type_description

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "data_model_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "data_model_type_label",
  { data_type => "char", is_nullable => 0, size => 64 },
  "data_model_type_description",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</data_model_type_id>

=back

=cut

__PACKAGE__->set_primary_key("data_model_type_id");

=head1 RELATIONS

=head2 data_model_type

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ClassType>

=cut

__PACKAGE__->belongs_to(
  "data_model_type",
  "AdministratorDB::Schema::Result::ClassType",
  { class_type_id => "data_model_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-03-28 18:50:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:svmIfCdJyXht57FmCC4geg


__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::ClassType",
  { class_type_id => "data_model_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);
1;
