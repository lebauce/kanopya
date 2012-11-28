package AdministratorDB::Schema::Result::Dashboard;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Dashboard

=cut

__PACKAGE__->table("dashboard");

=head1 ACCESSORS

=head2 dashboard_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 dashboard_config

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 dashboard_service_provider_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "dashboard_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "dashboard_config",
  { data_type => "char", is_nullable => 0, size => 64 },
  "dashboard_service_provider_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("dashboard_id");

=head1 RELATIONS

=head2 dashboard_service_provider

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "dashboard_service_provider",
  "AdministratorDB::Schema::Result::ServiceProvider",
  { service_provider_id => "dashboard_service_provider_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-06-06 15:11:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nN3s+Vl27PhUx3lT2IANpQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
