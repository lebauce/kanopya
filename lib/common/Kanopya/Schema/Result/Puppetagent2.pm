use utf8;
package Kanopya::Schema::Result::Puppetagent2;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Puppetagent2

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

=head1 TABLE: C<puppetagent2>

=cut

__PACKAGE__->table("puppetagent2");

=head1 ACCESSORS

=head2 puppetagent2_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 puppetagent2_options

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 puppetagent2_mode

  data_type: 'enum'
  default_value: 'kanopya'
  extra: {list => ["kanopya","custom"]}
  is_nullable: 0

=head2 puppetagent2_masterip

  data_type: 'char'
  is_nullable: 0
  size: 15

=head2 puppetagent2_masterfqdn

  data_type: 'char'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "puppetagent2_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "puppetagent2_options",
  { data_type => "char", is_nullable => 1, size => 255 },
  "puppetagent2_mode",
  {
    data_type => "enum",
    default_value => "kanopya",
    extra => { list => ["kanopya", "custom"] },
    is_nullable => 0,
  },
  "puppetagent2_masterip",
  { data_type => "char", is_nullable => 0, size => 15 },
  "puppetagent2_masterfqdn",
  { data_type => "char", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</puppetagent2_id>

=back

=cut

__PACKAGE__->set_primary_key("puppetagent2_id");

=head1 RELATIONS

=head2 puppetagent2

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "puppetagent2",
  "Kanopya::Schema::Result::Component",
  { component_id => "puppetagent2_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:y4cofMyGvNFGp69u4J/Uig


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
