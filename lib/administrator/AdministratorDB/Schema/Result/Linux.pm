package AdministratorDB::Schema::Result::Linux;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Linux

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
__PACKAGE__->set_primary_key("linux_id");

=head1 RELATIONS

=head2 linux

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "linux",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "linux_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 debian

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Debian>

=cut

__PACKAGE__->might_have(
  "debian",
  "AdministratorDB::Schema::Result::Debian",
  { "foreign.debian_id" => "self.linux_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 linuxs_mount

Type: has_many

Related object: L<AdministratorDB::Schema::Result::LinuxMount>

=cut

__PACKAGE__->has_many(
  "linuxs_mount",
  "AdministratorDB::Schema::Result::LinuxMount",
  { "foreign.linux_id" => "self.linux_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-05-28 11:11:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dwDENA8EGYqxIHNtAEGJkw


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Component",
        { "foreign.component_id" => "self.linux_id" },
        { cascade_copy => 0, cascade_delete => 1 });

1;
