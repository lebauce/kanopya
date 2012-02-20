package AdministratorDB::Schema::Result::Scom;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Scom

=cut

__PACKAGE__->table("scom");

=head1 ACCESSORS

=head2 scom_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 scom_ms_name

  data_type: 'char'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "scom_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "scom_ms_name",
  { data_type => "char", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("scom_id");

=head1 RELATIONS

=head2 scom

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Connector>

=cut

__PACKAGE__->belongs_to(
  "scom",
  "AdministratorDB::Schema::Result::Connector",
  { connector_id => "scom_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-02-20 11:11:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YbzawGCAHms2Ga0DhgHE4w

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Connector",
    { "foreign.connector_id" => "self.scom_id" },
    { cascade_copy => 0, cascade_delete => 1 });

1;
