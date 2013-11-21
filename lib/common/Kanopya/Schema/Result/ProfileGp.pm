use utf8;
package Kanopya::Schema::Result::ProfileGp;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::ProfileGp

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

=head1 TABLE: C<profile_gp>

=cut

__PACKAGE__->table("profile_gp");

=head1 ACCESSORS

=head2 profile_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 gp_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "profile_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "gp_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</profile_id>

=item * L</gp_id>

=back

=cut

__PACKAGE__->set_primary_key("profile_id", "gp_id");

=head1 RELATIONS

=head2 gp

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Gp>

=cut

__PACKAGE__->belongs_to(
  "gp",
  "Kanopya::Schema::Result::Gp",
  { gp_id => "gp_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 profile

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Profile>

=cut

__PACKAGE__->belongs_to(
  "profile",
  "Kanopya::Schema::Result::Profile",
  { profile_id => "profile_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TUfAbhMa0IL8Y7Jkgu1cpg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
