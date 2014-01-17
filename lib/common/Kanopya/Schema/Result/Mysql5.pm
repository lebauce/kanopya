use utf8;
package Kanopya::Schema::Result::Mysql5;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Mysql5

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

=head1 TABLE: C<mysql5>

=cut

__PACKAGE__->table("mysql5");

=head1 ACCESSORS

=head2 mysql5_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 mysql5_port

  data_type: 'integer'
  default_value: 3306
  extra: {unsigned => 1}
  is_nullable: 0

=head2 mysql5_datadir

  data_type: 'char'
  default_value: '/var/lib/mysql'
  is_nullable: 0
  size: 64

=head2 mysql5_bindaddress

  data_type: 'char'
  default_value: '127.0.0.1'
  is_nullable: 0
  size: 17

=cut

__PACKAGE__->add_columns(
  "mysql5_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "mysql5_port",
  {
    data_type => "integer",
    default_value => 3306,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "mysql5_datadir",
  {
    data_type => "char",
    default_value => "/var/lib/mysql",
    is_nullable => 0,
    size => 64,
  },
  "mysql5_bindaddress",
  {
    data_type => "char",
    default_value => "127.0.0.1",
    is_nullable => 0,
    size => 17,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</mysql5_id>

=back

=cut

__PACKAGE__->set_primary_key("mysql5_id");

=head1 RELATIONS

=head2 cinders

Type: has_many

Related object: L<Kanopya::Schema::Result::Cinder>

=cut

__PACKAGE__->has_many(
  "cinders",
  "Kanopya::Schema::Result::Cinder",
  { "foreign.mysql5_id" => "self.mysql5_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 glances

Type: has_many

Related object: L<Kanopya::Schema::Result::Glance>

=cut

__PACKAGE__->has_many(
  "glances",
  "Kanopya::Schema::Result::Glance",
  { "foreign.mysql5_id" => "self.mysql5_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 keystones

Type: has_many

Related object: L<Kanopya::Schema::Result::Keystone>

=cut

__PACKAGE__->has_many(
  "keystones",
  "Kanopya::Schema::Result::Keystone",
  { "foreign.mysql5_id" => "self.mysql5_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mysql5

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "mysql5",
  "Kanopya::Schema::Result::Component",
  { component_id => "mysql5_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 nova_controllers

Type: has_many

Related object: L<Kanopya::Schema::Result::NovaController>

=cut

__PACKAGE__->has_many(
  "nova_controllers",
  "Kanopya::Schema::Result::NovaController",
  { "foreign.mysql5_id" => "self.mysql5_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 quantums

Type: has_many

Related object: L<Kanopya::Schema::Result::Quantum>

=cut

__PACKAGE__->has_many(
  "quantums",
  "Kanopya::Schema::Result::Quantum",
  { "foreign.mysql5_id" => "self.mysql5_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xRX59IkhMvKWqv/jK1abxA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
