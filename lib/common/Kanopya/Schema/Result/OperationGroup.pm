use utf8;
package Kanopya::Schema::Result::OperationGroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::OperationGroup

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

=head1 TABLE: C<operation_group>

=cut

__PACKAGE__->table("operation_group");

=head1 ACCESSORS

=head2 operation_group_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "operation_group_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</operation_group_id>

=back

=cut

__PACKAGE__->set_primary_key("operation_group_id");

=head1 RELATIONS

=head2 operations

Type: has_many

Related object: L<Kanopya::Schema::Result::Operation>

=cut

__PACKAGE__->has_many(
  "operations",
  "Kanopya::Schema::Result::Operation",
  { "foreign.operation_group_id" => "self.operation_group_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-03-20 15:56:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gCHTiNANK7TUP3cl5QbtOg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
