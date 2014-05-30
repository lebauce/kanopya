use utf8;
package Kanopya::Schema::Result::DatabaseMigration;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::DatabaseMigration

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

=head1 TABLE: C<database_migration>

=cut

__PACKAGE__->table("database_migration");

=head1 ACCESSORS

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->set_primary_key("name");


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2014-05-14 14:07:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:D0QGuMtJejCeRCcNhzykKQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
