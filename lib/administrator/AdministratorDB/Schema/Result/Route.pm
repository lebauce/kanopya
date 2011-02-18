package AdministratorDB::Schema::Result::Route;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Route

=cut

__PACKAGE__->table("route");

=head1 ACCESSORS

=head2 route_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 publicip_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 ip_destination

  data_type: 'char'
  is_nullable: 0
  size: 39

=head2 gateway

  data_type: 'char'
  is_nullable: 1
  size: 39

=cut

__PACKAGE__->add_columns(
  "route_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "publicip_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "ip_destination",
  { data_type => "char", is_nullable => 0, size => 39 },
  "gateway",
  { data_type => "char", is_nullable => 1, size => 39 },
);
__PACKAGE__->set_primary_key("route_id");

=head1 RELATIONS

=head2 publicip

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Publicip>

=cut

__PACKAGE__->belongs_to(
  "publicip",
  "AdministratorDB::Schema::Result::Publicip",
  { publicip_id => "publicip_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KyEJcWgy+HZN6ot3nX73rQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
