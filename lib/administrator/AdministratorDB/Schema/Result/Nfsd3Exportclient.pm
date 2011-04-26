package AdministratorDB::Schema::Result::Nfsd3Exportclient;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Nfsd3Exportclient

=cut

__PACKAGE__->table("nfsd3_exportclient");

=head1 ACCESSORS

=head2 nfsd3_exportclient_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 nfsd3_export_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 nfsd3_exportclient_name

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 nfsd3_exportclient_options

  data_type: 'char'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "nfsd3_exportclient_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "nfsd3_export_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "nfsd3_exportclient_name",
  { data_type => "char", is_nullable => 0, size => 255 },
  "nfsd3_exportclient_options",
  { data_type => "char", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("nfsd3_exportclient_id");

=head1 RELATIONS

=head2 nfsd3_export

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Nfsd3Export>

=cut

__PACKAGE__->belongs_to(
  "nfsd3_export",
  "AdministratorDB::Schema::Result::Nfsd3Export",
  { nfsd3_export_id => "nfsd3_export_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-04-26 11:39:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ftQ+MhlibQ6BpOHF/oXcWA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
