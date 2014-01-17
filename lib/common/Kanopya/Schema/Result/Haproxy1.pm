use utf8;
package Kanopya::Schema::Result::Haproxy1;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Haproxy1

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

=head1 TABLE: C<haproxy1>

=cut

__PACKAGE__->table("haproxy1");

=head1 ACCESSORS

=head2 haproxy1_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "haproxy1_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</haproxy1_id>

=back

=cut

__PACKAGE__->set_primary_key("haproxy1_id");

=head1 RELATIONS

=head2 haproxy1

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "haproxy1",
  "Kanopya::Schema::Result::Component",
  { component_id => "haproxy1_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 haproxy1s_listen

Type: has_many

Related object: L<Kanopya::Schema::Result::Haproxy1Listen>

=cut

__PACKAGE__->has_many(
  "haproxy1s_listen",
  "Kanopya::Schema::Result::Haproxy1Listen",
  { "foreign.haproxy1_id" => "self.haproxy1_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XxRH5dgAqcuUctgxaCauug


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
