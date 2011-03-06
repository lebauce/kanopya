package AdministratorDB::Schema::Result::Motherboarddetail;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Motherboarddetail

=cut

__PACKAGE__->table("motherboarddetails");

=head1 ACCESSORS

=head2 motherboard_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 value

  data_type: 'char'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "motherboard_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "value",
  { data_type => "char", is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("motherboard_id", "name");

=head1 RELATIONS

=head2 motherboard

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Motherboard>

=cut

__PACKAGE__->belongs_to(
  "motherboard",
  "AdministratorDB::Schema::Result::Motherboard",
  { motherboard_id => "motherboard_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9dYS/x4KtlPBjFYO0bj+Xg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
