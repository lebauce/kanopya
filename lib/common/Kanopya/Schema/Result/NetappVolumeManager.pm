use utf8;
package Kanopya::Schema::Result::NetappVolumeManager;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::NetappVolumeManager

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

=head1 TABLE: C<netapp_volume_manager>

=cut

__PACKAGE__->table("netapp_volume_manager");

=head1 ACCESSORS

=head2 netapp_volume_manager_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "netapp_volume_manager_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</netapp_volume_manager_id>

=back

=cut

__PACKAGE__->set_primary_key("netapp_volume_manager_id");

=head1 RELATIONS

=head2 netapp_volume_manager

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "netapp_volume_manager",
  "Kanopya::Schema::Result::Component",
  { component_id => "netapp_volume_manager_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vMynGD1dLZi4pRShwOp2AQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
