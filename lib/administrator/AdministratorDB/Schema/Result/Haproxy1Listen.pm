package AdministratorDB::Schema::Result::Haproxy1Listen;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::IntrospectableM2M';

use base qw/DBIx::Class::Core/;

=head1 NAME

AdministratorDB::Schema::Result::Haproxy1Listen

=cut

__PACKAGE__->table("haproxy1_listen");

=head1 ACCESSORS

=head2 listen_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 haproxy1_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 listen_name

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 listen_ip

  data_type: 'char'
  default_value: '0.0.0.0'
  is_nullable: 0
  size: 17

=head2 listen_port

  data_type: 'integer'
  is_nullable: 0

=head2 listen_mode

  data_type: 'enum'
  default_value: 'tcp'
  extra: {list => ["tcp","http"]}
  is_nullable: 0

=head2 listen_balance

  data_type: 'enum'
  default_value: 'roundrobin'
  extra: {list => ["roundrobin"]}
  is_nullable: 0

=head2 component_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 component_port

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "listen_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "haproxy1_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "listen_name",
  { data_type => "char", is_nullable => 0, size => 64 },
  "listen_ip",
  {
    data_type => "char",
    default_value => "0.0.0.0",
    is_nullable => 0,
    size => 17,
  },
  "listen_port",
  { data_type => "integer", is_nullable => 0 },
  "listen_mode",
  {
    data_type => "enum",
    default_value => "tcp",
    extra => { list => ["tcp", "http"] },
    is_nullable => 0,
  },
  "listen_balance",
  {
    data_type => "enum",
    default_value => "roundrobin",
    extra => { list => ["roundrobin"] },
    is_nullable => 0,
  },
  "component_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "component_port",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("listen_id");

=head1 RELATIONS

=head2 haproxy1

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Haproxy1>

=cut

__PACKAGE__->belongs_to(
  "haproxy1",
  "AdministratorDB::Schema::Result::Haproxy1",
  { haproxy1_id => "haproxy1_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 component

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "component",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "component_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-06-04 17:35:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:J03n9Mu3QI1tRf6vdcxitA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
