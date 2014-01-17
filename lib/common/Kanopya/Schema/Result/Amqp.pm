use utf8;
package Kanopya::Schema::Result::Amqp;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Amqp

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

=head1 TABLE: C<amqp>

=cut

__PACKAGE__->table("amqp");

=head1 ACCESSORS

=head2 amqp_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 cookie

  data_type: 'char'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "amqp_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "cookie",
  { data_type => "char", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</amqp_id>

=back

=cut

__PACKAGE__->set_primary_key("amqp_id");

=head1 RELATIONS

=head2 amqp

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "amqp",
  "Kanopya::Schema::Result::Component",
  { component_id => "amqp_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 nova_controllers

Type: has_many

Related object: L<Kanopya::Schema::Result::NovaController>

=cut

__PACKAGE__->has_many(
  "nova_controllers",
  "Kanopya::Schema::Result::NovaController",
  { "foreign.amqp_id" => "self.amqp_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BWVzP7t1BRUNZwFpITGhRw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
