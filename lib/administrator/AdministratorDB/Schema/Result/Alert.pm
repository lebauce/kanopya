use utf8;
package AdministratorDB::Schema::Result::Alert;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Alert

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

=head1 TABLE: C<alert>

=cut

__PACKAGE__->table("alert");

=head1 ACCESSORS

=head2 alert_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 alert_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 alert_time

  data_type: 'time'
  is_nullable: 0

=head2 alert_message

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 alert_active

  data_type: 'integer'
  default_value: 1
  extra: {unsigned => 1}
  is_nullable: 0

=head2 entity_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 trigger_entity_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 alert_signature

  data_type: 'char'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "alert_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "alert_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 0 },
  "alert_time",
  { data_type => "time", is_nullable => 0 },
  "alert_message",
  { data_type => "char", is_nullable => 0, size => 255 },
  "alert_active",
  {
    data_type => "integer",
    default_value => 1,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "entity_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "trigger_entity_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "alert_signature",
  { data_type => "char", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</alert_id>

=back

=cut

__PACKAGE__->set_primary_key("alert_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<alert_signature>

=over 4

=item * L</alert_signature>

=back

=cut

__PACKAGE__->add_unique_constraint("alert_signature", ["alert_signature"]);

=head1 RELATIONS

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

=head2 trigger_entity

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "trigger_entity",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "trigger_entity_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2013-03-20 16:37:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ExkB9mSfaI56z2/M0CBJyw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
