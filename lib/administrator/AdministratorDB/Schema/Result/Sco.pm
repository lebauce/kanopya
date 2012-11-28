use utf8;
package AdministratorDB::Schema::Result::Sco;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Sco

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sco>

=cut

__PACKAGE__->table("sco");

=head1 ACCESSORS

=head2 sco_id

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "sco_id",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</sco_id>

=back

=cut

__PACKAGE__->set_primary_key("sco_id");

=head1 RELATIONS

=head2 sco

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Connector>

=cut

__PACKAGE__->belongs_to(
  "sco",
  "AdministratorDB::Schema::Result::Connector",
  { connector_id => "sco_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-06-08 14:15:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:R15rj5+bZtn9wOUtTbtvhg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Connector",
    { "foreign.connector_id" => "self.sco_id" },
    { cascade_copy => 0, cascade_delete => 1 }
);
1;
