package AdministratorDB::Schema::Result::ServiceTemplate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::ServiceTemplate

=cut

__PACKAGE__->table("service_template");

=head1 ACCESSORS

=head2 service_template_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 service_name

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 service_desc

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 hosting_policy_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 storage_policy_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 network_policy_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 scalability_policy_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 system_policy_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 billing_policy_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 orchestration_policy_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "service_template_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "service_name",
  { data_type => "char", is_nullable => 0, size => 64 },
  "service_desc",
  { data_type => "char", is_nullable => 1, size => 255 },
  "hosting_policy_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "storage_policy_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "network_policy_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "scalability_policy_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "system_policy_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "billing_policy_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "orchestration_policy_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("service_template_id");

=head1 RELATIONS

=head2 clusters

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Cluster>

=cut

__PACKAGE__->has_many(
  "clusters",
  "AdministratorDB::Schema::Result::Cluster",
  { "foreign.service_template_id" => "self.service_template_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_template

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "service_template",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "service_template_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 hosting_policy

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Policy>

=cut

__PACKAGE__->belongs_to(
  "hosting_policy",
  "AdministratorDB::Schema::Result::Policy",
  { policy_id => "hosting_policy_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 storage_policy

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Policy>

=cut

__PACKAGE__->belongs_to(
  "storage_policy",
  "AdministratorDB::Schema::Result::Policy",
  { policy_id => "storage_policy_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 network_policy

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Policy>

=cut

__PACKAGE__->belongs_to(
  "network_policy",
  "AdministratorDB::Schema::Result::Policy",
  { policy_id => "network_policy_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 scalability_policy

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Policy>

=cut

__PACKAGE__->belongs_to(
  "scalability_policy",
  "AdministratorDB::Schema::Result::Policy",
  { policy_id => "scalability_policy_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 billing_policy

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Policy>

=cut

__PACKAGE__->belongs_to(
  "billing_policy",
  "AdministratorDB::Schema::Result::Policy",
  { policy_id => "billing_policy_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 orchestration_policy

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Policy>

=cut

__PACKAGE__->belongs_to(
  "orchestration_policy",
  "AdministratorDB::Schema::Result::Policy",
  { policy_id => "orchestration_policy_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-08-14 15:34:03
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zenaRB3TdZKYaTtnVOfHEw

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "service_template_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
