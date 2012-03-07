package AdministratorDB::Schema::Result::ComponentProvided;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::ComponentProvided

=cut

__PACKAGE__->table("component_provided");

=head1 ACCESSORS

=head2 component_type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 masterimage_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "component_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "masterimage_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("component_type_id", "masterimage_id");

=head1 RELATIONS

=head2 component_type

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ComponentType>

=cut

__PACKAGE__->belongs_to(
  "component_type",
  "AdministratorDB::Schema::Result::ComponentType",
  { component_type_id => "component_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 masterimage

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Masterimage>

=cut

__PACKAGE__->belongs_to(
  "masterimage",
  "AdministratorDB::Schema::Result::Masterimage",
  { masterimage_id => "masterimage_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-03-05 17:35:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:C9h5WVOwkj6ibGBVnjQVoQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
