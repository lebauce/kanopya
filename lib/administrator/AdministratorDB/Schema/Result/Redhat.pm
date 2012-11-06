use utf8;
package AdministratorDB::Schema::Result::Redhat;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Redhat

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

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

Related object: L<AdministratorDB::Schema::Result::Linux>

=cut

__PACKAGE__->belongs_to(
  "redhat",
  "AdministratorDB::Schema::Result::Linux",
  { linux_id => "redhat_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-10-29 14:21:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZaPQdECDtKhIffUyQA4k4Q

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Linux",
  { "foreign.linux_id" => "self.redhat_id" },
  { cascade_copy => 0, cascade_delete => 1 }
);

1;
