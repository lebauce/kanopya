use utf8;
package Kanopya::Schema::Result::IscsiPortal;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::IscsiPortal

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

=head1 TABLE: C<iscsi_portal>

=cut

__PACKAGE__->table("iscsi_portal");

=head1 ACCESSORS

=head2 iscsi_portal_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 iscsi_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 iscsi_portal_ip

  data_type: 'char'
  is_nullable: 0
  size: 15

=head2 iscsi_portal_port

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "iscsi_portal_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "iscsi_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "iscsi_portal_ip",
  { data_type => "char", is_nullable => 0, size => 15 },
  "iscsi_portal_port",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</iscsi_portal_id>

=back

=cut

__PACKAGE__->set_primary_key("iscsi_portal_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<iscsi_portal_unique1>

=over 4

=item * L</iscsi_portal_id>

=item * L</iscsi_id>

=item * L</iscsi_portal_ip>

=item * L</iscsi_portal_port>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "iscsi_portal_unique1",
  [
    "iscsi_portal_id",
    "iscsi_id",
    "iscsi_portal_ip",
    "iscsi_portal_port",
  ],
);

=head1 RELATIONS

=head2 iscsi

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Iscsi>

=cut

__PACKAGE__->belongs_to(
  "iscsi",
  "Kanopya::Schema::Result::Iscsi",
  { iscsi_id => "iscsi_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:a937+tjznG1WQCS76yng6g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
