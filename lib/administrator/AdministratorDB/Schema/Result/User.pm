use utf8;
package AdministratorDB::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::User

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<user>

=cut

__PACKAGE__->table("user");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 user_system

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 user_login

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 user_password

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 user_firstname

  data_type: 'char'
  is_nullable: 1
  size: 64

=head2 user_lastname

  data_type: 'char'
  is_nullable: 1
  size: 64

=head2 user_email

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 user_creationdate

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 user_lastaccess

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 user_desc

  data_type: 'char'
  default_value: 'Note concerning this user'
  is_nullable: 1
  size: 255

=head2 user_sshkey

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "user_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "user_system",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "user_login",
  { data_type => "char", is_nullable => 0, size => 32 },
  "user_password",
  { data_type => "char", is_nullable => 0, size => 255 },
  "user_firstname",
  { data_type => "char", is_nullable => 1, size => 64 },
  "user_lastname",
  { data_type => "char", is_nullable => 1, size => 64 },
  "user_email",
  { data_type => "char", is_nullable => 1, size => 255 },
  "user_creationdate",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "user_lastaccess",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "user_desc",
  {
    data_type => "char",
    default_value => "Note concerning this user",
    is_nullable => 1,
    size => 255,
  },
  "user_sshkey",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_id>

=back

=cut

__PACKAGE__->set_primary_key("user_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<user_login>

=over 4

=item * L</user_login>

=back

=cut

__PACKAGE__->add_unique_constraint("user_login", ["user_login"]);

=head1 RELATIONS

=head2 clusters

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Cluster>

=cut

__PACKAGE__->has_many(
  "clusters",
  "AdministratorDB::Schema::Result::Cluster",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 messages

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Message>

=cut

__PACKAGE__->has_many(
  "messages",
  "AdministratorDB::Schema::Result::Message",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 old_operations

Type: has_many

Related object: L<AdministratorDB::Schema::Result::OldOperation>

=cut

__PACKAGE__->has_many(
  "old_operations",
  "AdministratorDB::Schema::Result::OldOperation",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 operations

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Operation>

=cut

__PACKAGE__->has_many(
  "operations",
  "AdministratorDB::Schema::Result::Operation",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 quotas

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Quota>

=cut

__PACKAGE__->has_many(
  "quotas",
  "AdministratorDB::Schema::Result::Quota",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "user",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "user_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 user_extensions

Type: has_many

Related object: L<AdministratorDB::Schema::Result::UserExtension>

=cut

__PACKAGE__->has_many(
  "user_extensions",
  "AdministratorDB::Schema::Result::UserExtension",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_profiles

Type: has_many

Related object: L<AdministratorDB::Schema::Result::UserProfile>

=cut

__PACKAGE__->has_many(
  "user_profiles",
  "AdministratorDB::Schema::Result::UserProfile",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 profiles

Type: many_to_many

Composing rels: L</user_profiles> -> profile

=cut

__PACKAGE__->many_to_many("profiles", "user_profiles", "profile");


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-10-26 13:48:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YbTdI3j8irDPts5so452+Q

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "user_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
