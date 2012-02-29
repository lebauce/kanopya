package AdministratorDB::Schema::Result::UnifiedComputingSystem;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::UnifiedComputingSystem

=cut

__PACKAGE__->table("unified_computing_system");

=head1 ACCESSORS

=head2 ucs_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 ucs_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 ucs_desc

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 ucs_addr

  data_type: 'char'
  is_nullable: 0
  size: 15

=cut

__PACKAGE__->add_columns(
  "ucs_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "ucs_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "ucs_desc",
  { data_type => "char", is_nullable => 1, size => 255 },
  "ucs_addr",
  { data_type => "char", is_nullable => 0, size => 15 },
  "ucs_state",
  { data_type => "char", default_value => "down", is_nullable => 0, size => 32 },
  "ucs_blade_number",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "ucs_login",
  { data_type => "char", is_nullable => 0, size => 32 },
  "ucs_passwd",
  { data_type => "char", is_nullable => 0, size => 32 },
  "ucs_dataprovider",
  { data_type => "char", is_nullable => 1, size => 32 },
  "ucs_ou",
  { data_type => "char", is_nullable => 1, size => 32 },
);
__PACKAGE__->set_primary_key("ucs_id");

=head1 RELATIONS

=head2 uc

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Outside>

=cut

__PACKAGE__->belongs_to(
  "uc",
  "AdministratorDB::Schema::Result::Outside",
  { outside_id => "ucs_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-02-24 10:51:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qWYJTCsbqQZE1kFxKazsKw

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Outside",
    { "foreign.outside_id" => "self.ucs_id" },
    { cascade_copy => 0, cascade_delete => 1 }
);

# You can replace this text with custom content, and it will be preserved on regeneration
1;
