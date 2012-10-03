package AdministratorDB::Schema::Result::Quota;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Quota

=cut

__PACKAGE__->table("quota");

=head1 ACCESSORS

=head2 quota_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 resource

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 current

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 limit

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "quota_id",
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
  "resource",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "current",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "limit",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("quota_id");

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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-10-03 14:14:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MGZCgBK1txvnV2xQGSrOog


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
