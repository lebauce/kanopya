use utf8;
package AdministratorDB::Schema::Result::Vsphere5Datacenter;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Vsphere5Datacenter

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<vsphere5_datacenter>

=cut

__PACKAGE__->table("vsphere5_datacenter");

=head1 ACCESSORS

=head2 vsphere5_datacenter_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 vsphere5_datacenter_name

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 vsphere5_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "vsphere5_datacenter_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "vsphere5_datacenter_name",
  { data_type => "char", is_nullable => 0, size => 255 },
  "vsphere5_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</vsphere5_datacenter_id>

=back

=cut

__PACKAGE__->set_primary_key("vsphere5_datacenter_id");

=head1 RELATIONS

=head2 vsphere5

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Vsphere5>

=cut

__PACKAGE__->belongs_to(
  "vsphere5",
  "AdministratorDB::Schema::Result::Vsphere5",
  { vsphere5_id => "vsphere5_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-08-23 17:42:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oAT1OxFw65pVtpMCp6EZkA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
