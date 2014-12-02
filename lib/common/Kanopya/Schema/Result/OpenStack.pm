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

=head1 UNIQUE CONSTRAINTS

=head2 C<keystone_url>

=over 4

=item * L</keystone_url>

=item * L</tenant_name>

=back

=cut

__PACKAGE__->add_unique_constraint("keystone_url", ["keystone_url", "tenant_name"]);

=head1 RELATIONS

=head2 keystone_endpoints

Type: has_many

Related object: L<Kanopya::Schema::Result::KeystoneEndpoint>

=cut

__PACKAGE__->has_many(
  "keystone_endpoints",
  "Kanopya::Schema::Result::KeystoneEndpoint",
  { "foreign.open_stack_id" => "self.open_stack_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 open_stack

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Virtualization>

=cut

__PACKAGE__->belongs_to(
  "open_stack",
  "Kanopya::Schema::Result::Virtualization",
  { virtualization_id => "open_stack_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-12-02 17:12:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bBgmFsEb+zrDOJq7jWz/FA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
