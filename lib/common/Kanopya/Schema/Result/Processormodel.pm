use utf8;
package Kanopya::Schema::Result::Processormodel;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Processormodel

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

=head1 TABLE: C<processormodel>

=cut

__PACKAGE__->table("processormodel");

=head1 ACCESSORS

=head2 processormodel_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 processormodel_brand

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 processormodel_name

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 processormodel_core_num

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 processormodel_clock_speed

  data_type: 'float'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 processormodel_l2_cache

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 processormodel_max_tdp

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 processormodel_64bits

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 processormodel_virtsupport

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "processormodel_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "processormodel_brand",
  { data_type => "char", is_nullable => 0, size => 64 },
  "processormodel_name",
  { data_type => "char", is_nullable => 0, size => 64 },
  "processormodel_core_num",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "processormodel_clock_speed",
  { data_type => "float", extra => { unsigned => 1 }, is_nullable => 0 },
  "processormodel_l2_cache",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "processormodel_max_tdp",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "processormodel_64bits",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "processormodel_virtsupport",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</processormodel_id>

=back

=cut

__PACKAGE__->set_primary_key("processormodel_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<processormodel_name>

=over 4

=item * L</processormodel_name>

=back

=cut

__PACKAGE__->add_unique_constraint("processormodel_name", ["processormodel_name"]);

=head1 RELATIONS

=head2 hostmodels

Type: has_many

Related object: L<Kanopya::Schema::Result::Hostmodel>

=cut

__PACKAGE__->has_many(
  "hostmodels",
  "Kanopya::Schema::Result::Hostmodel",
  { "foreign.processormodel_id" => "self.processormodel_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 hosts

Type: has_many

Related object: L<Kanopya::Schema::Result::Host>

=cut

__PACKAGE__->has_many(
  "hosts",
  "Kanopya::Schema::Result::Host",
  { "foreign.processormodel_id" => "self.processormodel_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 processormodel

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "processormodel",
  "Kanopya::Schema::Result::Entity",
  { entity_id => "processormodel_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Wwq5CymlTQtOInEivouAOA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
