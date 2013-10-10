use utf8;
package AdministratorDB::Schema::Result::EntityState;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::EntityState

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<DBIx::Class::IntrospectableM2M>

=cut

use base 'DBIx::Class::IntrospectableM2M';

=head1 LEFT BASE CLASSES

=over 4

=item * L<DBIx::Class::Core>

=back

=cut

use base qw/DBIx::Class::Core/;

=head1 TABLE: C<entity_state>

=cut

__PACKAGE__->table("entity_state");

=head1 ACCESSORS

=head2 entity_state_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 entity_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 consumer_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 state

  data_type: 'char'
  is_nullable: 1
  size: 32

=head2 prev_state

  data_type: 'char'
  is_nullable: 1
  size: 32

=cut

__PACKAGE__->add_columns(
  "entity_state_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "entity_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "consumer_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "state",
  { data_type => "char", is_nullable => 1, size => 32 },
  "prev_state",
  { data_type => "char", is_nullable => 1, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</entity_state_id>

=back

=cut

__PACKAGE__->set_primary_key("entity_state_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<entity_id>

=over 4

=item * L</entity_id>

=item * L</consumer_id>

=back

=cut

__PACKAGE__->add_unique_constraint("entity_id", ["entity_id", "consumer_id"]);

=head1 RELATIONS

=head2 consumer

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "consumer",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "consumer_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 entity

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "entity",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "entity_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2013-06-13 10:51:12
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bgiQQUaHtFcTgUrrE/TRug


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
