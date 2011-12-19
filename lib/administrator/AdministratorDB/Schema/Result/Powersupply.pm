package AdministratorDB::Schema::Result::Powersupply;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Powersupply

=cut

__PACKAGE__->table("powersupply");

=head1 ACCESSORS

=head2 powersupply_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 powersupplycard_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 powersupplyport_number

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "powersupply_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "powersupplycard_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "powersupplyport_number",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("powersupply_id");

=head1 RELATIONS

=head2 hosts

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Host>

=cut

__PACKAGE__->has_many(
  "hosts",
  "AdministratorDB::Schema::Result::Host",
  { "foreign.host_powersupply_id" => "self.powersupply_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 powersupplycard

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Powersupplycard>

=cut

__PACKAGE__->belongs_to(
  "powersupplycard",
  "AdministratorDB::Schema::Result::Powersupplycard",
  { powersupplycard_id => "powersupplycard_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/ynNBhPqm8k+4V58ozo/sQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
