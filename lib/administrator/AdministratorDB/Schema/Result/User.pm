package AdministratorDB::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::User

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
  size: 32

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
  is_nullable: 1

=head2 user_lastaccess

  data_type: 'datetime'
  is_nullable: 1

=head2 user_desc

  data_type: 'char'
  default_value: 'Note concerning this user'
  is_nullable: 1
  size: 255

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
  { data_type => "char", is_nullable => 0, size => 32 },
  "user_firstname",
  { data_type => "char", is_nullable => 1, size => 64 },
  "user_lastname",
  { data_type => "char", is_nullable => 1, size => 64 },
  "user_email",
  { data_type => "char", is_nullable => 1, size => 255 },
  "user_creationdate",
  { data_type => "date", is_nullable => 1 },
  "user_lastaccess",
  { data_type => "datetime", is_nullable => 1 },
  "user_desc",
  {
    data_type => "char",
    default_value => "Note concerning this user",
    is_nullable => 1,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("user_id");
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


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-06-06 18:14:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:C784XTsBimwwIIl6CnVclQ

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "user_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);
1;
