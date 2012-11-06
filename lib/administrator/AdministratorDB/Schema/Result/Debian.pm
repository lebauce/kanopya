use utf8;
package AdministratorDB::Schema::Result::Debian;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Debian

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<debian>

=cut

__PACKAGE__->table("debian");

=head1 ACCESSORS

=head2 debian_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "debian_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</debian_id>

=back

=cut

__PACKAGE__->set_primary_key("debian_id");

=head1 RELATIONS

=head2 debian

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "debian",
  "AdministratorDB::Schema::Result::Linux",
  { linux_id => "debian_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-10-29 00:36:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3o+ec+mkD2REMw8IgkQc/A

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Linux",
  { linux_id => "debian_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
