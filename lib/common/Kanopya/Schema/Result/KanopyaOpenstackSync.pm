use utf8;
package Kanopya::Schema::Result::KanopyaOpenstackSync;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::KanopyaOpenstackSync

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

=head1 TABLE: C<kanopya_openstack_sync>

=cut

__PACKAGE__->table("kanopya_openstack_sync");

=head1 ACCESSORS

=head2 kanopya_openstack_sync_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 control_queue

  data_type: 'char'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "kanopya_openstack_sync_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "control_queue",
  { data_type => "char", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</kanopya_openstack_sync_id>

=back

=cut

__PACKAGE__->set_primary_key("kanopya_openstack_sync_id");

=head1 RELATIONS

=head2 kanopya_openstack_sync

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "kanopya_openstack_sync",
  "Kanopya::Schema::Result::Component",
  { component_id => "kanopya_openstack_sync_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 nova_controllers

Type: has_many

Related object: L<Kanopya::Schema::Result::NovaController>

=cut

__PACKAGE__->has_many(
  "nova_controllers",
  "Kanopya::Schema::Result::NovaController",
  {
    "foreign.kanopya_openstack_sync_id" => "self.kanopya_openstack_sync_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-01-07 12:21:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lQeElFDHFOA3g0abpfv/sw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
