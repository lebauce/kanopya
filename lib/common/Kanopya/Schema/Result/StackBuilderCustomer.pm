use utf8;
package Kanopya::Schema::Result::StackBuilderCustomer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::StackBuilderCustomer

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

=head1 TABLE: C<stack_builder_customer>

=cut

__PACKAGE__->table("stack_builder_customer");

=head1 ACCESSORS

=head2 stack_builder_customer_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "stack_builder_customer_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</stack_builder_customer_id>

=back

=cut

__PACKAGE__->set_primary_key("stack_builder_customer_id");

=head1 RELATIONS

=head2 stack_builder_customer

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Customer>

=cut

__PACKAGE__->belongs_to(
  "stack_builder_customer",
  "Kanopya::Schema::Result::Customer",
  { customer_id => "stack_builder_customer_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-04-18 16:35:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FgfWZ2ZmnVZ/1gSzcMjjlQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
