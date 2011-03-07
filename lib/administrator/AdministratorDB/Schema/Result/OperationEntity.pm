package AdministratorDB::Schema::Result::OperationEntity;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::OperationEntity

=cut

__PACKAGE__->table("operation_entity");

=head1 ACCESSORS

=head2 entity_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 operation_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "entity_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "operation_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("entity_id", "operation_id");
__PACKAGE__->add_unique_constraint("fk_operation_entity_1", ["entity_id"]);
__PACKAGE__->add_unique_constraint("fk_operation_entity_2", ["operation_id"]);

=head1 RELATIONS

=head2 entity

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "entity",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "entity_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 operation

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Operation>

=cut

__PACKAGE__->belongs_to(
  "operation",
  "AdministratorDB::Schema::Result::Operation",
  { operation_id => "operation_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QmO+4PJhuHWdLSSWg8xmJA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
