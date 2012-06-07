package AdministratorDB::Schema::Result::UserExtension;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::UserExtension

=cut

__PACKAGE__->table("user_extension");

=head1 ACCESSORS

=head2 user_extension_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 user_extension_key

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 user_extension_value

  data_type: 'char'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "user_extension_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "user_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "user_extension_key",
  { data_type => "char", is_nullable => 0, size => 32 },
  "user_extension_value",
  { data_type => "char", is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("user_extension_id");
__PACKAGE__->add_unique_constraint("user_id", ["user_id", "user_extension_key"]);

=head1 RELATIONS

=head2 user

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "AdministratorDB::Schema::Result::User",
  { user_id => "user_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-06-06 18:14:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dPLkk7GkoIXD+vHsBi+cfw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
