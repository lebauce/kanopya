package AdministratorDB::Schema::Result::Physicalhoster0;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Physicalhoster0

=cut

__PACKAGE__->table("physicalhoster0");

=head1 ACCESSORS

=head2 physicalhoster0_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "physicalhoster0_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("physicalhoster0_id");

=head1 RELATIONS

=head2 physicalhoster0

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "physicalhoster0",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "physicalhoster0_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-02-27 16:02:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KW+Kva+t+4R8PiS8YrQ/Kg
__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Component",
    { "foreign.component_id" => "self.physicalhoster0_id" },
    { cascade_copy => 0, cascade_delete => 1 }
);

# You can replace this text with custom content, and it will be preserved on regeneration
1;
