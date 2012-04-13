package AdministratorDB::Schema::Result::LvmContainer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::LvmContainer

=cut

__PACKAGE__->table("lvm_container");

=head1 ACCESSORS

=head2 lvm_container_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 lv_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "lvm_container_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "lv_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("lvm_container_id");

=head1 RELATIONS

=head2 lvm_container

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Container>

=cut

__PACKAGE__->belongs_to(
  "lvm_container",
  "AdministratorDB::Schema::Result::Container",
  { container_id => "lvm_container_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-02-16 20:32:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:G8X2JVV3zRM0aNd1Ea6mFg

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Container",
  { "foreign.container_id" => "self.lvm_container_id" },
  { cascade_copy => 0, cascade_delete => 1 }
);

1;
