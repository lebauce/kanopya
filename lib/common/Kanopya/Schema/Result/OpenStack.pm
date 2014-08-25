use utf8;
package Kanopya::Schema::Result::OpenStack;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::OpenStack

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

=head1 TABLE: C<open_stack>

=cut

__PACKAGE__->table("open_stack");

=head1 ACCESSORS

=head2 open_stack_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 api_username

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 api_password

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 keystone_url

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 tenant_name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "open_stack_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "api_username",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "api_password",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "keystone_url",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "tenant_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</open_stack_id>

=back

=cut

__PACKAGE__->set_primary_key("open_stack_id");

=head1 RELATIONS

=head2 open_stack

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "open_stack",
  "Kanopya::Schema::Result::Component",
  { component_id => "open_stack_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-08-22 14:07:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DsVBUDEefBl41ibymQl4yQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
