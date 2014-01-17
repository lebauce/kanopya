use utf8;
package Kanopya::Schema::Result::Redhat;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Redhat

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

=head1 TABLE: C<redhat>

=cut

__PACKAGE__->table("redhat");

=head1 ACCESSORS

=head2 redhat_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "redhat_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</redhat_id>

=back

=cut

__PACKAGE__->set_primary_key("redhat_id");

=head1 RELATIONS

=head2 redhat

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Linux>

=cut

__PACKAGE__->belongs_to(
  "redhat",
  "Kanopya::Schema::Result::Linux",
  { linux_id => "redhat_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gHM7FR4VZYQvcI0+exFefA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
