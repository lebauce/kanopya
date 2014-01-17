use utf8;
package Kanopya::Schema::Result::Php5;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Php5

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

=head1 TABLE: C<php5>

=cut

__PACKAGE__->table("php5");

=head1 ACCESSORS

=head2 php5_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 php5_session_handler

  data_type: 'enum'
  default_value: 'files'
  extra: {list => ["files","memcache"]}
  is_nullable: 0

=head2 php5_session_path

  data_type: 'char'
  is_nullable: 0
  size: 127

=cut

__PACKAGE__->add_columns(
  "php5_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "php5_session_handler",
  {
    data_type => "enum",
    default_value => "files",
    extra => { list => ["files", "memcache"] },
    is_nullable => 0,
  },
  "php5_session_path",
  { data_type => "char", is_nullable => 0, size => 127 },
);

=head1 PRIMARY KEY

=over 4

=item * L</php5_id>

=back

=cut

__PACKAGE__->set_primary_key("php5_id");

=head1 RELATIONS

=head2 php5

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "php5",
  "Kanopya::Schema::Result::Component",
  { component_id => "php5_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uRjwOUVP/jCIMGwoH1vLHg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
