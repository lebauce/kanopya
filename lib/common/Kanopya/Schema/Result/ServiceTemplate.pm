use utf8;
package Kanopya::Schema::Result::ServiceTemplate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::ServiceTemplate

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

=head1 TABLE: C<service_template>

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
  is_foreign_key: 1
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
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
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

=head1 PRIMARY KEY

=over 4

=item * L</service_template_id>

=back

=cut

__PACKAGE__->set_primary_key("service_template_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<service_name>

=over 4

=item * L</service_name>

=back

=cut

__PACKAGE__->add_unique_constraint("service_name", ["service_name"]);

=head1 RELATIONS

=head2 billing_policy

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Policy>

=cut

__PACKAGE__->belongs_to(
  "billing_policy",
  "Kanopya::Schema::Result::Policy",
  { policy_id => "billing_policy_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 clusters

Type: has_many

Related object: L<Kanopya::Schema::Result::Cluster>

=cut

__PACKAGE__->has_many(
  "clusters",
  "Kanopya::Schema::Result::Cluster",
  { "foreign.service_template_id" => "self.service_template_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 hosting_policy

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Policy>

=cut

__PACKAGE__->belongs_to(
  "hosting_policy",
  "Kanopya::Schema::Result::Policy",
  { policy_id => "hosting_policy_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 network_policy

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Policy>

=cut

__PACKAGE__->belongs_to(
  "network_policy",
  "Kanopya::Schema::Result::Policy",
  { policy_id => "network_policy_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 orchestration_policy

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Policy>

=cut

__PACKAGE__->belongs_to(
  "orchestration_policy",
  "Kanopya::Schema::Result::Policy",
  { policy_id => "orchestration_policy_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 scalability_policy

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Policy>

=cut

__PACKAGE__->belongs_to(
  "scalability_policy",
  "Kanopya::Schema::Result::Policy",
  { policy_id => "scalability_policy_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 service_template

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "service_template",
  "Kanopya::Schema::Result::Entity",
  { entity_id => "service_template_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 storage_policy

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Policy>

=cut

__PACKAGE__->belongs_to(
  "storage_policy",
  "Kanopya::Schema::Result::Policy",
  { policy_id => "storage_policy_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 system_policy

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Policy>

=cut

__PACKAGE__->belongs_to(
  "system_policy",
  "Kanopya::Schema::Result::Policy",
  { policy_id => "system_policy_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-02-04 16:46:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xP2CZwc4Pnalui6HWC4s/w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
