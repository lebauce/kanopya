package AdministratorDB::Schema::Result::ServiceProviderManager;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::ServiceProviderManager

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

=head2 manager_type

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
  "manager_type",
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
__PACKAGE__->set_primary_key("service_provider_manager_id");

=head1 RELATIONS

=head2 service_provider

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "service_provider",
  "AdministratorDB::Schema::Result::ServiceProvider",
  { service_provider_id => "service_provider_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 param_preset

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ParamPreset>

=cut

__PACKAGE__->belongs_to(
  "param_preset",
  "AdministratorDB::Schema::Result::ParamPreset",
  { param_preset_id => "param_preset_id" },
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-06-13 17:32:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YXKQMaXctOjjDpTtoE1nGg


# You can replace this text with custom content, and it will be preserved on regeneration
1;