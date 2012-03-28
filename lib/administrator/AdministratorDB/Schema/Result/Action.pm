package AdministratorDB::Schema::Result::Action;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Action

=cut

__PACKAGE__->table("action");

=head1 ACCESSORS

=head2 action_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 action_service_provider_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 action_name

  data_type: 'char'
  is_nullable: 0
  size: 64

=cut

__PACKAGE__->add_columns(
  "action_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "action_service_provider_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "action_name",
  { data_type => "char", is_nullable => 0, size => 64 },
);
__PACKAGE__->set_primary_key("action_id");

=head1 RELATIONS

=head2 action_service_provider

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "action_service_provider",
  "AdministratorDB::Schema::Result::ServiceProvider",
  { service_provider_id => "action_service_provider_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 action_parameters

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ActionParameter>

=cut

__PACKAGE__->has_many(
  "action_parameters",
  "AdministratorDB::Schema::Result::ActionParameter",
  { "foreign.action_parameter_action_id" => "self.action_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 actions_triggered

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ActionTriggered>

=cut

__PACKAGE__->has_many(
  "actions_triggered",
  "AdministratorDB::Schema::Result::ActionTriggered",
  { "foreign.action_triggered_action_id" => "self.action_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-28 12:37:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zAFN5jTmwBpvOiuNCgpziA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
