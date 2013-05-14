use utf8;
package AdministratorDB::Schema::Result::Harddisk;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Harddisk

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

=head1 TABLE: C<harddisk>

=cut

__PACKAGE__->table("harddisk");

=head1 ACCESSORS

=head2 harddisk_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 host_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 harddisk_device

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 harddisk_size

  data_type: 'bigint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "harddisk_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "host_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "harddisk_device",
  { data_type => "char", is_nullable => 0, size => 32 },
  "harddisk_size",
  {
    data_type => "bigint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  'service_provider_id',
  {
    data_type => 'int',
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1
  }
);

=head1 PRIMARY KEY

=over 4

=item * L</harddisk_id>

=back

=cut

__PACKAGE__->set_primary_key("harddisk_id");

=head1 RELATIONS

=head2 host

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Host>

=cut

__PACKAGE__->belongs_to(
  "host",
  "AdministratorDB::Schema::Result::Host",
  { host_id => "host_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-12-28 18:04:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3ci3d/SV6zsyj+hJa+AQvQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
