use utf8;
package Kanopya::Schema::Result::Operationtype;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Operationtype

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

=head1 TABLE: C<operationtype>

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

=head2 operationtype_label

  data_type: 'char'
  is_nullable: 1
  size: 128

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
  "operationtype_label",
  { data_type => "char", is_nullable => 1, size => 128 },
);

=head1 PRIMARY KEY

=over 4

=item * L</operationtype_id>

=back

=cut

__PACKAGE__->set_primary_key("operationtype_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<operationtype_name>

=over 4

=item * L</operationtype_name>

=back

=cut

__PACKAGE__->add_unique_constraint("operationtype_name", ["operationtype_name"]);

=head1 RELATIONS

=head2 notification_subscriptions

Type: has_many

Related object: L<Kanopya::Schema::Result::NotificationSubscription>

=cut

__PACKAGE__->has_many(
  "notification_subscriptions",
  "Kanopya::Schema::Result::NotificationSubscription",
  { "foreign.operationtype_id" => "self.operationtype_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 old_operations

Type: has_many

Related object: L<Kanopya::Schema::Result::OldOperation>

=cut

__PACKAGE__->has_many(
  "old_operations",
  "Kanopya::Schema::Result::OldOperation",
  { "foreign.operationtype_id" => "self.operationtype_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 operations

Type: has_many

Related object: L<Kanopya::Schema::Result::Operation>

=cut

__PACKAGE__->has_many(
  "operations",
  "Kanopya::Schema::Result::Operation",
  { "foreign.operationtype_id" => "self.operationtype_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workflow_steps

Type: has_many

Related object: L<Kanopya::Schema::Result::WorkflowStep>

=cut

__PACKAGE__->has_many(
  "workflow_steps",
  "Kanopya::Schema::Result::WorkflowStep",
  { "foreign.operationtype_id" => "self.operationtype_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aDbiMZ9jt6zZmEHUmoGVPQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
