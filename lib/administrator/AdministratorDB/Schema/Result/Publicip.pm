package AdministratorDB::Schema::Result::Publicip;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Publicip

=cut

__PACKAGE__->table("publicip");

=head1 ACCESSORS

=head2 publicip_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 ip_address

  data_type: 'char'
  is_nullable: 0
  size: 39

=head2 ip_mask

  data_type: 'char'
  is_nullable: 0
  size: 39

=head2 gateway

  data_type: 'char'
  is_nullable: 1
  size: 39

=head2 cluster_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "publicip_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "ip_address",
  { data_type => "char", is_nullable => 0, size => 39 },
  "ip_mask",
  { data_type => "char", is_nullable => 0, size => 39 },
  "gateway",
  { data_type => "char", is_nullable => 1, size => 39 },
  "cluster_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("publicip_id");

=head1 RELATIONS

=head2 cluster

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Cluster>

=cut

__PACKAGE__->belongs_to(
  "cluster",
  "AdministratorDB::Schema::Result::Cluster",
  { cluster_id => "cluster_id" },
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 routes

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Route>

=cut

__PACKAGE__->has_many(
  "routes",
  "AdministratorDB::Schema::Result::Route",
  { "foreign.publicip_id" => "self.publicip_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Mh5iQtLRfTvG9miF3uFYkw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
