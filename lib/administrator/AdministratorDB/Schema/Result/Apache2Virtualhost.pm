package AdministratorDB::Schema::Result::Apache2Virtualhost;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Apache2Virtualhost

=cut

__PACKAGE__->table("apache2_virtualhost");

=head1 ACCESSORS

=head2 apache2_virtualhost_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 apache2_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 apache2_virtualhost_servername

  data_type: 'char'
  is_nullable: 1
  size: 128

=head2 apache2_virtualhost_sslenable

  data_type: 'integer'
  is_nullable: 1

=head2 apache2_virtualhost_serveradmin

  data_type: 'char'
  is_nullable: 1
  size: 64

=head2 apache2_virtualhost_documentroot

  data_type: 'char'
  is_nullable: 1
  size: 128

=head2 apache2_virtualhost_log

  data_type: 'char'
  is_nullable: 1
  size: 128

=head2 apache2_virtualhost_errorlog

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=cut

__PACKAGE__->add_columns(
  "apache2_virtualhost_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "apache2_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "apache2_virtualhost_servername",
  { data_type => "char", is_nullable => 1, size => 128 },
  "apache2_virtualhost_sslenable",
  { data_type => "integer", is_nullable => 1 },
  "apache2_virtualhost_serveradmin",
  { data_type => "char", is_nullable => 1, size => 64 },
  "apache2_virtualhost_documentroot",
  { data_type => "char", is_nullable => 1, size => 128 },
  "apache2_virtualhost_log",
  { data_type => "char", is_nullable => 1, size => 128 },
  "apache2_virtualhost_errorlog",
  { data_type => "varchar", is_nullable => 1, size => 45 },
);
__PACKAGE__->set_primary_key("apache2_virtualhost_id");

=head1 RELATIONS

=head2 apache2

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Apache2>

=cut

__PACKAGE__->belongs_to(
  "apache2",
  "AdministratorDB::Schema::Result::Apache2",
  { apache2_id => "apache2_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-25 14:17:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HfgeCZblj1Up+fY4qhBdMg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
