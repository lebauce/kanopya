package AdministratorDB::Schema::Result::Atftpd0;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Atftpd0

=cut

__PACKAGE__->table("atftpd0");

=head1 ACCESSORS

=head2 atftpd0_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 component_instance_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 atftpd0_options

  data_type: 'char'
  is_nullable: 1
  size: 128

=head2 atftpd0_use_inetd

  data_type: 'char'
  is_nullable: 1
  size: 32

=head2 atftpd0_logfile

  data_type: 'char'
  is_nullable: 1
  size: 128

=head2 atftpd0_repository

  data_type: 'char'
  is_nullable: 1
  size: 64

=cut

__PACKAGE__->add_columns(
  "atftpd0_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "component_instance_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "atftpd0_options",
  { data_type => "char", is_nullable => 1, size => 128 },
  "atftpd0_use_inetd",
  { data_type => "char", is_nullable => 1, size => 32 },
  "atftpd0_logfile",
  { data_type => "char", is_nullable => 1, size => 128 },
  "atftpd0_repository",
  { data_type => "char", is_nullable => 1, size => 64 },
);
__PACKAGE__->set_primary_key("atftpd0_id");

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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:q85taoIyUQDQvrrOoPp4fQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
