package AdministratorDB::Schema::Result::NetappAggregate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::NetappAggregate

=cut

__PACKAGE__->table("netapp_aggregate");

=head1 ACCESSORS

=head2 aggregate_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'char'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "aggregate_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "char", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("aggregate_id");

=head1 RELATIONS

=head2 aggregate

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "aggregate",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "aggregate_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 netapp_volumes

Type: has_many

Related object: L<AdministratorDB::Schema::Result::NetappVolume>

=cut

__PACKAGE__->has_many(
  "netapp_volumes",
  "AdministratorDB::Schema::Result::NetappVolume",
  { "foreign.aggregate_id" => "self.aggregate_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-04-18 17:21:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oYviahWL5X3JZC7r1YZ7lw

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
  { "foreign.entity_id" => "self.aggregate_id" },
  { cascade_copy => 0, cascade_delete => 1 }
);

1;
