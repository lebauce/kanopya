package AdministratorDB::Schema::Result::Mailnotifier0;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Mailnotifier0

=cut

__PACKAGE__->table("mailnotifier0");

=head1 ACCESSORS

=head2 mailnotifier0_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 smtp_server

  data_type: 'char'
  default_value: 'localhost'
  is_nullable: 1
  size: 255

=head2 smtp_login

  data_type: 'char'
  is_nullable: 1
  size: 32

=head2 smtp_passwd

  data_type: 'char'
  is_nullable: 1
  size: 32

=head2 use_ssl

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "mailnotifier0_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "smtp_server",
  {
    data_type => "char",
    default_value => "localhost",
    is_nullable => 1,
    size => 255,
  },
  "smtp_login",
  { data_type => "char", is_nullable => 1, size => 32 },
  "smtp_passwd",
  { data_type => "char", is_nullable => 1, size => 32 },
  "use_ssl",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("mailnotifier0_id");

=head1 RELATIONS

=head2 mailnotifier0

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "mailnotifier0",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "mailnotifier0_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-08-13 17:11:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:12PeoCiy/nxuHwhjFkERJg

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "mailnotifier0_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
