package AdministratorDB::Schema::Result::Operationtype;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Operationtype

=cut

__PACKAGE__->table("operationtype");

=head1 ACCESSORS

=head2 operationtype_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 operationtype_name

  data_type: 'char'
  is_nullable: 1
  size: 64

=cut

__PACKAGE__->add_columns(
  "operationtype_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "operationtype_name",
  { data_type => "char", is_nullable => 1, size => 64 },
);
__PACKAGE__->set_primary_key("operationtype_id");
__PACKAGE__->add_unique_constraint("operationtype_name", ["operationtype_name"]);

=head1 RELATIONS

=head2 old_operations

Type: has_many

Related object: L<AdministratorDB::Schema::Result::OldOperation>

=cut

__PACKAGE__->has_many(
  "old_operations",
  "AdministratorDB::Schema::Result::OldOperation",
  { "foreign.type" => "self.operationtype_name" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 operations

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Operation>

=cut

__PACKAGE__->has_many(
  "operations",
  "AdministratorDB::Schema::Result::Operation",
  { "foreign.type" => "self.operationtype_name" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-02-02 10:20:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Cxs4Hkd0Py3dzBid3HSaog


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::Result::OperationtypeEntity",
    { "foreign.operationtype_id" => "self.operationtype_id" },
    { cascade_copy => 0, cascade_delete => 0 });
1;
