use utf8;
package Kanopya::Schema::Result::Openiscsi2;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Openiscsi2

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

=head1 TABLE: C<openiscsi2>

=cut

__PACKAGE__->table("openiscsi2");

=head1 ACCESSORS

=head2 openiscsi2_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "openiscsi2_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</openiscsi2_id>

=back

=cut

__PACKAGE__->set_primary_key("openiscsi2_id");

=head1 RELATIONS

=head2 openiscsi2

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "openiscsi2",
  "Kanopya::Schema::Result::Component",
  { component_id => "openiscsi2_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 openiscsi2_targets

Type: has_many

Related object: L<Kanopya::Schema::Result::Openiscsi2Target>

=cut

__PACKAGE__->has_many(
  "openiscsi2_targets",
  "Kanopya::Schema::Result::Openiscsi2Target",
  { "foreign.openiscsi2_id" => "self.openiscsi2_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+SOnGPOx2eyfTHTmjpzOsw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
