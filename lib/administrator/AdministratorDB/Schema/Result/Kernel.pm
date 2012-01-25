package AdministratorDB::Schema::Result::Kernel;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Kernel

=cut

__PACKAGE__->table("kernel");

=head1 ACCESSORS

=head2 kernel_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 kernel_name

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 kernel_version

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 kernel_desc

  data_type: 'char'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "kernel_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "kernel_name",
  { data_type => "char", is_nullable => 0, size => 64 },
  "kernel_version",
  { data_type => "char", is_nullable => 0, size => 32 },
  "kernel_desc",
  { data_type => "char", is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("kernel_id");

=head1 RELATIONS

=head2 dhcpd3_hosts

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Dhcpd3Host>

=cut

__PACKAGE__->has_many(
  "dhcpd3_hosts",
  "AdministratorDB::Schema::Result::Dhcpd3Host",
  { "foreign.kernel_id" => "self.kernel_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 hosts

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Host>

=cut

__PACKAGE__->has_many(
  "hosts",
  "AdministratorDB::Schema::Result::Host",
  { "foreign.kernel_id" => "self.kernel_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 kernel

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "kernel",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "kernel_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-25 14:19:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vTbt5qpRL6bXNuVQmf2mNA

# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
    { "foreign.entity_id" => "self.kernel_id" },
    { cascade_copy => 0, cascade_delete => 1 });

1;
