use utf8;
package Kanopya::Schema::Result::Hostmodel;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Hostmodel

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

=head1 TABLE: C<hostmodel>

=cut

__PACKAGE__->table("hostmodel");

=head1 ACCESSORS

=head2 hostmodel_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 hostmodel_brand

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 hostmodel_name

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 hostmodel_chipset

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 hostmodel_processor_num

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 hostmodel_consumption

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 hostmodel_iface_num

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 hostmodel_ram_slot_num

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 hostmodel_ram_max

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 processormodel_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "hostmodel_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "hostmodel_brand",
  { data_type => "char", is_nullable => 0, size => 64 },
  "hostmodel_name",
  { data_type => "char", is_nullable => 0, size => 64 },
  "hostmodel_chipset",
  { data_type => "char", is_nullable => 0, size => 64 },
  "hostmodel_processor_num",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "hostmodel_consumption",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "hostmodel_iface_num",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "hostmodel_ram_slot_num",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "hostmodel_ram_max",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "processormodel_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</hostmodel_id>

=back

=cut

__PACKAGE__->set_primary_key("hostmodel_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<hostmodel_name>

=over 4

=item * L</hostmodel_name>

=back

=cut

__PACKAGE__->add_unique_constraint("hostmodel_name", ["hostmodel_name"]);

=head1 RELATIONS

=head2 hostmodel

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "hostmodel",
  "Kanopya::Schema::Result::Entity",
  { entity_id => "hostmodel_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 hosts

Type: has_many

Related object: L<Kanopya::Schema::Result::Host>

=cut

__PACKAGE__->has_many(
  "hosts",
  "Kanopya::Schema::Result::Host",
  { "foreign.hostmodel_id" => "self.hostmodel_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 processormodel

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Processormodel>

=cut

__PACKAGE__->belongs_to(
  "processormodel",
  "Kanopya::Schema::Result::Processormodel",
  { processormodel_id => "processormodel_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:B2Mu8QvM0aiaF/4YkkPJOw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
