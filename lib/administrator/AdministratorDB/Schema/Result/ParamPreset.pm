use utf8;
package AdministratorDB::Schema::Result::ParamPreset;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::ParamPreset

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

=head1 TABLE: C<param_preset>

=cut

__PACKAGE__->table("param_preset");

=head1 ACCESSORS

=head2 param_preset_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 params

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "param_preset_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "params",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</param_preset_id>

=back

=cut

__PACKAGE__->set_primary_key("param_preset_id");

=head1 RELATIONS

=head2 policies

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Policy>

=cut

__PACKAGE__->has_many(
  "policies",
  "AdministratorDB::Schema::Result::Policy",
  { "foreign.param_preset_id" => "self.param_preset_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_provider_managers

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ServiceProviderManager>

=cut

__PACKAGE__->has_many(
  "service_provider_managers",
  "AdministratorDB::Schema::Result::ServiceProviderManager",
  { "foreign.param_preset_id" => "self.param_preset_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workflow_defs

Type: has_many

Related object: L<AdministratorDB::Schema::Result::WorkflowDef>

=cut

__PACKAGE__->has_many(
  "workflow_defs",
  "AdministratorDB::Schema::Result::WorkflowDef",
  { "foreign.param_preset_id" => "self.param_preset_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-11-16 17:31:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ytkja2bXugtZBZLzs8XPtQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
