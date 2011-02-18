package AdministratorDB::Schema::Result::Entityright;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Entityright

=cut

__PACKAGE__->table("entityright");

=head1 ACCESSORS

=head2 entityright_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 entityright_consumed_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 entityright_consumer_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 entityright_method

  data_type: 'char'
  is_nullable: 0
  size: 64

=cut

__PACKAGE__->add_columns(
  "entityright_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "entityright_consumed_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "entityright_consumer_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "entityright_method",
  { data_type => "char", is_nullable => 0, size => 64 },
);
__PACKAGE__->set_primary_key("entityright_id");
__PACKAGE__->add_unique_constraint(
  "entityright_right",
  [
    "entityright_consumed_id",
    "entityright_consumer_id",
    "entityright_method",
  ],
);

=head1 RELATIONS

=head2 entityright_consumed

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "entityright_consumed",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "entityright_consumed_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 entityright_consumer

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "entityright_consumer",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "entityright_consumer_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DJW2wxRqrd7/ba2cG7MGMg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
