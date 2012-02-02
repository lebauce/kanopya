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

=cut

__PACKAGE__->add_columns(
  "ucs_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
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
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-02-02 11:02:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QZawjkSLq5yW48wmUz+uQw

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Outside",
    { "foreign.outside_id" => "self.ucs_id" },
    { cascade_copy => 0, cascade_delete => 1 });

1;
