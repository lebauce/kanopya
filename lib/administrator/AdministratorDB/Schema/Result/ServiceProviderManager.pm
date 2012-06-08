use utf8;
package AdministratorDB::Schema::Result::ServiceProviderManager;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::ServiceProviderManager

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<service_provider_manager>

=cut

__PACKAGE__->table("service_provider_manager");

=head1 ACCESSORS

=head2 service_provider_manager_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 service_provider_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 service_provider_manager_type

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 manager_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 param_preset_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "service_provider_manager_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "service_provider_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "service_provider_manager_type",
  { data_type => "char", is_nullable => 0, size => 64 },
  "manager_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "param_preset_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</service_provider_manager_id>

=back

=cut

__PACKAGE__->set_primary_key("service_provider_manager_id");

=head1 RELATIONS

=head2 param_preset

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ParamPreset>

=cut

__PACKAGE__->belongs_to(
  "param_preset",
  "AdministratorDB::Schema::Result::ParamPreset",
  { param_preset_id => "param_preset_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 service_provider

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "service_provider",
  "AdministratorDB::Schema::Result::ServiceProvider",
  { service_provider_id => "service_provider_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-06-07 15:58:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bEqDyQ4k3G761xydokpUEw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
