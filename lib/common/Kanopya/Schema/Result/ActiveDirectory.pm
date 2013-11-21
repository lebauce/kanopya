use utf8;
package Kanopya::Schema::Result::ActiveDirectory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::ActiveDirectory

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

=head1 TABLE: C<active_directory>

=cut

__PACKAGE__->table("active_directory");

=head1 ACCESSORS

=head2 ad_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 ad_host

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 ad_user

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 ad_pwd

  data_type: 'char'
  is_nullable: 1
  size: 32

=head2 ad_nodes_base_dn

  data_type: 'text'
  is_nullable: 1

=head2 ad_usessl

  data_type: 'integer'
  default_value: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "ad_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "ad_host",
  { data_type => "char", is_nullable => 1, size => 255 },
  "ad_user",
  { data_type => "char", is_nullable => 1, size => 255 },
  "ad_pwd",
  { data_type => "char", is_nullable => 1, size => 32 },
  "ad_nodes_base_dn",
  { data_type => "text", is_nullable => 1 },
  "ad_usessl",
  { data_type => "integer", default_value => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</ad_id>

=back

=cut

__PACKAGE__->set_primary_key("ad_id");

=head1 RELATIONS

=head2 ad

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "ad",
  "Kanopya::Schema::Result::Component",
  { component_id => "ad_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xehmi1rGuzIREzsHNk2/SA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
