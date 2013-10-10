use utf8;
package AdministratorDB::Schema::Result::Scom;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Scom

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

=head1 TABLE: C<scom>

=cut

__PACKAGE__->table("scom");

=head1 ACCESSORS

=head2 scom_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 scom_ms_name

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 scom_usessl

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "scom_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "scom_ms_name",
  { data_type => "char", is_nullable => 1, size => 255 },
  "scom_usessl",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</scom_id>

=back

=cut

__PACKAGE__->set_primary_key("scom_id");

=head1 RELATIONS

=head2 scom

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "scom",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "scom_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2013-01-31 11:35:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JzKzH9OpQ05AtJiYAQl4Jg

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "scom_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
