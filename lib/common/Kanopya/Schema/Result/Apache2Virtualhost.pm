use utf8;
package Kanopya::Schema::Result::Apache2Virtualhost;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Apache2Virtualhost

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

=head1 TABLE: C<apache2_virtualhost>

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

=head1 PRIMARY KEY

=over 4

=item * L</apache2_virtualhost_id>

=back

=cut

__PACKAGE__->set_primary_key("apache2_virtualhost_id");

=head1 RELATIONS

=head2 apache2

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Apache2>

=cut

__PACKAGE__->belongs_to(
  "apache2",
  "Kanopya::Schema::Result::Apache2",
  { apache2_id => "apache2_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/yvJM7/pgkaV5NTV+ERjxQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
