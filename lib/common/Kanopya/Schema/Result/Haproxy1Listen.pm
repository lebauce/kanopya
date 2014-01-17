use utf8;
package Kanopya::Schema::Result::Haproxy1Listen;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Haproxy1Listen

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

=head1 TABLE: C<haproxy1_listen>

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

=head2 listen_component_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 listen_component_port

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
  "listen_component_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "listen_component_port",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</listen_id>

=back

=cut

__PACKAGE__->set_primary_key("listen_id");

=head1 RELATIONS

=head2 haproxy1

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Haproxy1>

=cut

__PACKAGE__->belongs_to(
  "haproxy1",
  "Kanopya::Schema::Result::Haproxy1",
  { haproxy1_id => "haproxy1_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 listen_component

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "listen_component",
  "Kanopya::Schema::Result::Component",
  { component_id => "listen_component_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cWBDGBSlqEMCXzkOipxwQQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
