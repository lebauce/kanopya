package AdministratorDB::Schema::Result::Openiscsi2;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Openiscsi2

=cut

__PACKAGE__->table("openiscsi2");

=head1 ACCESSORS

=head2 openiscsi2_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 component_instance_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 openiscsi2_target

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 openiscsi2_server

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 openiscsi2_port

  data_type: 'integer'
  is_nullable: 1

=head2 openiscsi2_mount_point

  data_type: 'char'
  is_nullable: 1
  size: 64

=head2 openiscsi2_mount_options

  data_type: 'char'
  is_nullable: 1
  size: 64

=head2 openiscsi2_filesystem

  data_type: 'char'
  is_nullable: 1
  size: 32

=cut

__PACKAGE__->add_columns(
  "openiscsi2_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "component_instance_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "openiscsi2_target",
  { data_type => "char", is_nullable => 0, size => 64 },
  "openiscsi2_server",
  { data_type => "char", is_nullable => 0, size => 32 },
  "openiscsi2_port",
  { data_type => "integer", is_nullable => 1 },
  "openiscsi2_mount_point",
  { data_type => "char", is_nullable => 1, size => 64 },
  "openiscsi2_mount_options",
  { data_type => "char", is_nullable => 1, size => 64 },
  "openiscsi2_filesystem",
  { data_type => "char", is_nullable => 1, size => 32 },
);
__PACKAGE__->set_primary_key("openiscsi2_id");

=head1 RELATIONS

=head2 component_instance

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ComponentInstance>

=cut

__PACKAGE__->belongs_to(
  "component_instance",
  "AdministratorDB::Schema::Result::ComponentInstance",
  { component_instance_id => "component_instance_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-25 14:17:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fn9Wzyuj1ROH6ajB+BrQyQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
