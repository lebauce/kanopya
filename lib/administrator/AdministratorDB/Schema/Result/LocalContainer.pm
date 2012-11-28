package AdministratorDB::Schema::Result::LocalContainer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::LocalContainer

=cut

__PACKAGE__->table("local_container");

=head1 ACCESSORS

=head2 local_container_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "local_container_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("local_container_id");

=head1 RELATIONS

=head2 local_container

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Container>

=cut

__PACKAGE__->belongs_to(
  "local_container",
  "AdministratorDB::Schema::Result::Container",
  { container_id => "local_container_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-10-16 11:49:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8+jFV15e+eiG1bxjjprhFQ

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Container",
  { container_id => "local_container_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
