package AdministratorDB::Schema::Result::ProfileGp;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::ProfileGp

=cut

__PACKAGE__->table("profile_gp");

=head1 ACCESSORS

=head2 profile_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 gp_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "profile_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "gp_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("profile_id", "gp_id");

=head1 RELATIONS

=head2 profile

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Profile>

=cut

__PACKAGE__->belongs_to(
  "profile",
  "AdministratorDB::Schema::Result::Profile",
  { profile_id => "profile_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 gp

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Gp>

=cut

__PACKAGE__->belongs_to(
  "gp",
  "AdministratorDB::Schema::Result::Gp",
  { gp_id => "gp_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-07-27 15:30:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gWbSFvWTuKfx/0E6gnajHw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
