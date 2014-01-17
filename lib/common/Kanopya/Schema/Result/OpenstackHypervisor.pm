use utf8;
package Kanopya::Schema::Result::OpenstackHypervisor;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::OpenstackHypervisor

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

=head1 TABLE: C<openstack_hypervisor>

=cut

__PACKAGE__->table("openstack_hypervisor");

=head1 ACCESSORS

=head2 openstack_hypervisor_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 nova_controller_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "openstack_hypervisor_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "nova_controller_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</openstack_hypervisor_id>

=back

=cut

__PACKAGE__->set_primary_key("openstack_hypervisor_id");

=head1 RELATIONS

=head2 nova_controller

Type: belongs_to

Related object: L<Kanopya::Schema::Result::NovaController>

=cut

__PACKAGE__->belongs_to(
  "nova_controller",
  "Kanopya::Schema::Result::NovaController",
  { nova_controller_id => "nova_controller_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 openstack_hypervisor

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Hypervisor>

=cut

__PACKAGE__->belongs_to(
  "openstack_hypervisor",
  "Kanopya::Schema::Result::Hypervisor",
  { hypervisor_id => "openstack_hypervisor_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YoRWR82+wXnbLbjheIRKUw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
