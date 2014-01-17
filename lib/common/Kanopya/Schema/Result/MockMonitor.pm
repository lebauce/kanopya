use utf8;
package Kanopya::Schema::Result::MockMonitor;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::MockMonitor

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

=head1 TABLE: C<mock_monitor>

=cut

__PACKAGE__->table("mock_monitor");

=head1 ACCESSORS

=head2 mock_monitor_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "mock_monitor_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</mock_monitor_id>

=back

=cut

__PACKAGE__->set_primary_key("mock_monitor_id");

=head1 RELATIONS

=head2 mock_monitor

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "mock_monitor",
  "Kanopya::Schema::Result::Component",
  { component_id => "mock_monitor_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ALFgpiOHwC2XcUIEKH1VEQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
