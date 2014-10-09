use utf8;
package Kanopya::Schema::Result::KeystoneEndpoint;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::KeystoneEndpoint

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

=head1 TABLE: C<keystone_endpoint>

=cut

__PACKAGE__->table("keystone_endpoint");

=head1 ACCESSORS

=head2 open_stack_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 keystone_uuid

  data_type: 'char'
  is_nullable: 0
  size: 64

=cut

__PACKAGE__->add_columns(
  "open_stack_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "keystone_uuid",
  { data_type => "char", is_nullable => 0, size => 64 },
);

=head1 PRIMARY KEY

=over 4

=item * L</keystone_uuid>

=back

=cut

__PACKAGE__->set_primary_key("keystone_uuid");

=head1 RELATIONS

=head2 open_stack

Type: belongs_to

Related object: L<Kanopya::Schema::Result::OpenStack>

=cut

__PACKAGE__->belongs_to(
  "open_stack",
  "Kanopya::Schema::Result::OpenStack",
  { open_stack_id => "open_stack_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-09-30 11:44:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Kx2py9/LYFgyOdgn104Aug


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
