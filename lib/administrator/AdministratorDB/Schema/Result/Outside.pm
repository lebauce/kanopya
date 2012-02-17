package AdministratorDB::Schema::Result::Outside;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Outside

=cut

__PACKAGE__->table("outside");

=head1 ACCESSORS

=head2 outside_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "outside_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("outside_id");

=head1 RELATIONS

=head2 connectors

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Connector>

=cut

__PACKAGE__->has_many(
  "connectors",
  "AdministratorDB::Schema::Result::Connector",
  { "foreign.outside_id" => "self.outside_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 netapp

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Netapp>

=cut

__PACKAGE__->might_have(
  "netapp",
  "AdministratorDB::Schema::Result::Netapp",
  { "foreign.netapp_id" => "self.outside_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 outside

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "outside",
  "AdministratorDB::Schema::Result::ServiceProvider",
  { service_provider_id => "outside_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 unified_computing_system

Type: might_have

Related object: L<AdministratorDB::Schema::Result::UnifiedComputingSystem>

=cut

__PACKAGE__->might_have(
  "unified_computing_system",
  "AdministratorDB::Schema::Result::UnifiedComputingSystem",
  { "foreign.ucs_id" => "self.outside_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 externalcluster

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Externalcluster>

=cut

__PACKAGE__->might_have(
  "externalcluster",
  "AdministratorDB::Schema::Result::Externalcluster",
  { "foreign.externalcluster_id" => "self.outside_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 externalnodes

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Externalnode>

=cut

__PACKAGE__->has_many(
  "externalnodes",
  "AdministratorDB::Schema::Result::Externalnode",
  { "foreign.outside_id" => "self.outside_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-02-02 11:02:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:d4EotSWCHCcLIjG+IhmVNw

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::ServiceProvider",
    { "foreign.service_provider_id" => "self.outside_id" },
    { cascade_copy => 0, cascade_delete => 1 });
    
1;
