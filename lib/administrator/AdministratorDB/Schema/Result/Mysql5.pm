use utf8;
package AdministratorDB::Schema::Result::Mysql5;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Mysql5

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

=head2 glances

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Glance>

=cut

__PACKAGE__->has_many(
  "glances",
  "AdministratorDB::Schema::Result::Glance",
  { "foreign.mysql5_id" => "self.mysql5_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 keystones

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Keystone>

=cut

__PACKAGE__->has_many(
  "keystones",
  "AdministratorDB::Schema::Result::Keystone",
  { "foreign.mysql5_id" => "self.mysql5_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mysql5

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "mysql5",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "mysql5_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 nova_controllers

Type: has_many

Related object: L<AdministratorDB::Schema::Result::NovaController>

=cut

__PACKAGE__->has_many(
  "nova_controllers",
  "AdministratorDB::Schema::Result::NovaController",
  { "foreign.mysql5_id" => "self.mysql5_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 novas_compute

Type: has_many

Related object: L<AdministratorDB::Schema::Result::NovaCompute>

=cut

__PACKAGE__->has_many(
  "novas_compute",
  "AdministratorDB::Schema::Result::NovaCompute",
  { "foreign.mysql5_id" => "self.mysql5_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 quantums

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Quantum>

=cut

__PACKAGE__->has_many(
  "quantums",
  "AdministratorDB::Schema::Result::Quantum",
  { "foreign.mysql5_id" => "self.mysql5_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-02-08 16:34:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:U7gh7ubtOrs+fjlVUeuOQQ
# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->belongs_to(
    "parent",
    "AdministratorDB::Schema::Result::Component",
      { "foreign.component_id" => "self.mysql5_id" },
      { cascade_copy => 0, cascade_delete => 1 });

1;
