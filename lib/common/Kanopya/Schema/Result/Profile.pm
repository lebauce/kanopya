use utf8;
package Kanopya::Schema::Result::Profile;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Profile

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

=head1 TABLE: C<profile>

=cut

__PACKAGE__->table("profile");

=head1 ACCESSORS

=head2 profile_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 profile_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 profile_desc

  data_type: 'char'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "profile_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "profile_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "profile_desc",
  { data_type => "char", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</profile_id>

=back

=cut

__PACKAGE__->set_primary_key("profile_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<profile_name>

=over 4

=item * L</profile_name>

=back

=cut

__PACKAGE__->add_unique_constraint("profile_name", ["profile_name"]);

=head1 RELATIONS

=head2 profile_gps

Type: has_many

Related object: L<Kanopya::Schema::Result::ProfileGp>

=cut

__PACKAGE__->has_many(
  "profile_gps",
  "Kanopya::Schema::Result::ProfileGp",
  { "foreign.profile_id" => "self.profile_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_profiles

Type: has_many

Related object: L<Kanopya::Schema::Result::UserProfile>

=cut

__PACKAGE__->has_many(
  "user_profiles",
  "Kanopya::Schema::Result::UserProfile",
  { "foreign.profile_id" => "self.profile_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gps

Type: many_to_many

Composing rels: L</profile_gps> -> gp

=cut

__PACKAGE__->many_to_many("gps", "profile_gps", "gp");

=head2 users

Type: many_to_many

Composing rels: L</user_profiles> -> user

=cut

__PACKAGE__->many_to_many("users", "user_profiles", "user");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XFXqaK1zrWzRdGyRSOwiQA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
