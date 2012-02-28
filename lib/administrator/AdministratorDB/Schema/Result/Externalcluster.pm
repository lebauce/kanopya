package AdministratorDB::Schema::Result::Externalcluster;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Externalcluster

=cut

__PACKAGE__->table("externalcluster");

=head1 ACCESSORS

=head2 externalcluster_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 externalcluster_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 externalcluster_desc

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 externalcluster_state

  data_type: 'char'
  default_value: 'down'
  is_nullable: 0
  size: 32

=head2 externalcluster_prev_state

  data_type: 'char'
  is_nullable: 1
  size: 32

=cut

__PACKAGE__->add_columns(
  "externalcluster_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "externalcluster_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "externalcluster_desc",
  { data_type => "char", is_nullable => 1, size => 255 },
  "externalcluster_state",
  { data_type => "char", default_value => "down", is_nullable => 0, size => 32 },
  "externalcluster_prev_state",
  { data_type => "char", is_nullable => 1, size => 32 },
    "class_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("externalcluster_id");
__PACKAGE__->add_unique_constraint("externalcluster_name", ["externalcluster_name"]);

=head1 RELATIONS

=head2 externalcluster

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Outside>

=cut

__PACKAGE__->belongs_to(
  "externalcluster",
  "AdministratorDB::Schema::Result::Outside",
  { outside_id => "externalcluster_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-02-15 13:58:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UiKPOJ4hNTi4PEa7qh6wQA

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Outside",
    { "foreign.outside_id" => "self.externalcluster_id" },
    { cascade_copy => 0, cascade_delete => 1 });
    
1;
