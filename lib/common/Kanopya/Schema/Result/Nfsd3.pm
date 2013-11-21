use utf8;
package Kanopya::Schema::Result::Nfsd3;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Nfsd3

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

=head1 TABLE: C<nfsd3>

=cut

__PACKAGE__->table("nfsd3");

=head1 ACCESSORS

=head2 nfsd3_id

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

=head1 PRIMARY KEY

=over 4

=item * L</nfsd3_id>

=back

=cut

__PACKAGE__->set_primary_key("nfsd3_id");

=head1 RELATIONS

=head2 nfsd3

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "nfsd3",
  "Kanopya::Schema::Result::Component",
  { component_id => "nfsd3_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ozJBltGuYOMnghTOLKrKpA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
