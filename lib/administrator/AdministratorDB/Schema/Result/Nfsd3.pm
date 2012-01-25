package AdministratorDB::Schema::Result::Nfsd3;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Nfsd3

=cut

__PACKAGE__->table("nfsd3");

=head1 ACCESSORS

=head2 nfsd3_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 component_instance_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 nfsd3_statdopts

  data_type: 'char'
  is_nullable: 1
  size: 128

=head2 nfsd3_need_gssd

  data_type: 'enum'
  default_value: 'no'
  extra: {list => ["yes","no"]}
  is_nullable: 0

=head2 nfsd3_rpcnfsdcount

  data_type: 'integer'
  default_value: 8
  extra: {unsigned => 1}
  is_nullable: 0

=head2 nfsd3_rpcnfsdpriority

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 nfsd3_rpcmountopts

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 nfsd3_need_svcgssd

  data_type: 'enum'
  default_value: 'no'
  extra: {list => ["yes","no"]}
  is_nullable: 0

=head2 nfsd3_rpcsvcgssdopts

  data_type: 'char'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "nfsd3_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "component_instance_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "nfsd3_statdopts",
  { data_type => "char", is_nullable => 1, size => 128 },
  "nfsd3_need_gssd",
  {
    data_type => "enum",
    default_value => "no",
    extra => { list => ["yes", "no"] },
    is_nullable => 0,
  },
  "nfsd3_rpcnfsdcount",
  {
    data_type => "integer",
    default_value => 8,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "nfsd3_rpcnfsdpriority",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "nfsd3_rpcmountopts",
  { data_type => "char", is_nullable => 1, size => 255 },
  "nfsd3_need_svcgssd",
  {
    data_type => "enum",
    default_value => "no",
    extra => { list => ["yes", "no"] },
    is_nullable => 0,
  },
  "nfsd3_rpcsvcgssdopts",
  { data_type => "char", is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("nfsd3_id");

=head1 RELATIONS

=head2 component_instance

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ComponentInstance>

=cut

__PACKAGE__->belongs_to(
  "component_instance",
  "AdministratorDB::Schema::Result::ComponentInstance",
  { component_instance_id => "component_instance_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 nfsd3_exports

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Nfsd3Export>

=cut

__PACKAGE__->has_many(
  "nfsd3_exports",
  "AdministratorDB::Schema::Result::Nfsd3Export",
  { "foreign.nfsd3_id" => "self.nfsd3_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-25 14:17:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UnL5ugbyWYofCpIjbDSL3A



# You can replace this text with custom content, and it will be preserved on regeneration
1;
