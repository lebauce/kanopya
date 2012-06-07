package AdministratorDB::Schema::Result::Profile;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Profile

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
__PACKAGE__->set_primary_key("profile_id");
__PACKAGE__->add_unique_constraint("profile_name", ["profile_name"]);

=head1 RELATIONS

=head2 user_profiles

Type: has_many

Related object: L<AdministratorDB::Schema::Result::UserProfile>

=cut

__PACKAGE__->has_many(
  "user_profiles",
  "AdministratorDB::Schema::Result::UserProfile",
  { "foreign.profile_id" => "self.profile_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-06-06 17:51:03
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:s+lubVdPDzFQZoO2tngYmw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
