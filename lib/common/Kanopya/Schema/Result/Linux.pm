use utf8;
package Kanopya::Schema::Result::Linux;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Linux

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

=head1 TABLE: C<linux>

=cut

__PACKAGE__->table("linux");

=head1 ACCESSORS

=head2 linux_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "linux_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</linux_id>

=back

=cut

__PACKAGE__->set_primary_key("linux_id");

=head1 RELATIONS

=head2 debian

Type: might_have

Related object: L<Kanopya::Schema::Result::Debian>

=cut

__PACKAGE__->might_have(
  "debian",
  "Kanopya::Schema::Result::Debian",
  { "foreign.debian_id" => "self.linux_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 linux

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "linux",
  "Kanopya::Schema::Result::Component",
  { component_id => "linux_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 linuxes_mount

Type: has_many

Related object: L<Kanopya::Schema::Result::LinuxMount>

=cut

__PACKAGE__->has_many(
  "linuxes_mount",
  "Kanopya::Schema::Result::LinuxMount",
  { "foreign.linux_id" => "self.linux_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 redhat

Type: might_have

Related object: L<Kanopya::Schema::Result::Redhat>

=cut

__PACKAGE__->might_have(
  "redhat",
  "Kanopya::Schema::Result::Redhat",
  { "foreign.redhat_id" => "self.linux_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 suse

Type: might_have

Related object: L<Kanopya::Schema::Result::Suse>

=cut

__PACKAGE__->might_have(
  "suse",
  "Kanopya::Schema::Result::Suse",
  { "foreign.suse_id" => "self.linux_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dDbFi92loq1dDYcCr80xfw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
