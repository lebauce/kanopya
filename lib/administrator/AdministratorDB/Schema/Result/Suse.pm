use utf8;
package AdministratorDB::Schema::Result::Suse;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Suse

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<suse>

=cut

__PACKAGE__->table("suse");

=head1 ACCESSORS

=head2 suse_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "suse_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</suse_id>

=back

=cut

__PACKAGE__->set_primary_key("suse_id");

=head1 RELATIONS

=head2 suse

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Linux>

=cut

__PACKAGE__->belongs_to(
  "suse",
  "AdministratorDB::Schema::Result::Linux",
  { linux_id => "suse_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-10-29 20:28:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uok08dSlewNnt5s0svHT3A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
