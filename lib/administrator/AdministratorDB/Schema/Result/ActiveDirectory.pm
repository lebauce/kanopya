package AdministratorDB::Schema::Result::ActiveDirectory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::ActiveDirectory

=cut

__PACKAGE__->table("active_directory");

=head1 ACCESSORS

=head2 ad_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 ad_host

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 ad_user

  data_type: 'char'
  is_nullable: 1
  size: 32

=head2 ad_pwd

  data_type: 'char'
  is_nullable: 1
  size: 32

=cut

__PACKAGE__->add_columns(
  "ad_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "ad_host",
  { data_type => "char", is_nullable => 0, size => 32 },
  "ad_user",
  { data_type => "char", is_nullable => 1, size => 32 },
  "ad_pwd",
  { data_type => "char", is_nullable => 1, size => 32 },
);
__PACKAGE__->set_primary_key("ad_id");

=head1 RELATIONS

=head2 ad

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Connector>

=cut

__PACKAGE__->belongs_to(
  "ad",
  "AdministratorDB::Schema::Result::Connector",
  { connector_id => "ad_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-02-17 14:45:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Bi1D2AZwddeE3P9lhAghWg

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Connector",
    { "foreign.connector_id" => "self.ad_id" },
    { cascade_copy => 0, cascade_delete => 1 });

1;
