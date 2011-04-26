package AdministratorDB::Schema::Result::Nfsd3Export;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Nfsd3Export

=cut

__PACKAGE__->table("nfsd3_export");

=head1 ACCESSORS

=head2 nfsd3_export_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 nfsd3_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 nfsd3_export_path

  data_type: 'char'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "nfsd3_export_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "nfsd3_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "nfsd3_export_path",
  { data_type => "char", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("nfsd3_export_id");

=head1 RELATIONS

=head2 nfsd3

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Nfsd3>

=cut

__PACKAGE__->belongs_to(
  "nfsd3",
  "AdministratorDB::Schema::Result::Nfsd3",
  { nfsd3_id => "nfsd3_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 nfsd3_exportclients

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Nfsd3Exportclient>

=cut

__PACKAGE__->has_many(
  "nfsd3_exportclients",
  "AdministratorDB::Schema::Result::Nfsd3Exportclient",
  { "foreign.nfsd3_export_id" => "self.nfsd3_export_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-04-26 11:39:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4t4ZLXoyCjc5PkPM1kmZeg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
