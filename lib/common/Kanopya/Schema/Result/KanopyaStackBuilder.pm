use utf8;
package Kanopya::Schema::Result::KanopyaStackBuilder;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::KanopyaStackBuilder

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

=head1 TABLE: C<kanopya_stack_builder>

=cut

__PACKAGE__->table("kanopya_stack_builder");

=head1 ACCESSORS

=head2 kanopya_stack_builder_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 support_user_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "kanopya_stack_builder_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "support_user_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</kanopya_stack_builder_id>

=back

=cut

__PACKAGE__->set_primary_key("kanopya_stack_builder_id");

=head1 RELATIONS

=head2 kanopya_stack_builder

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "kanopya_stack_builder",
  "Kanopya::Schema::Result::Component",
  { component_id => "kanopya_stack_builder_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 support_user

Type: belongs_to

Related object: L<Kanopya::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "support_user",
  "Kanopya::Schema::Result::User",
  { user_id => "support_user_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-03-26 15:17:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:woMnRcOC1h+aEr3I3ACD3A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
