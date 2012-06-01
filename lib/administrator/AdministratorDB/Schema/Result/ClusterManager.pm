package AdministratorDB::Schema::Result::ClusterManager;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::ClusterManager

=cut

__PACKAGE__->table("cluster_manager");

=head1 ACCESSORS

=head2 cluster_manager_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 cluster_id

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

=head2 manager_params

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "cluster_manager_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "cluster_id",
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
  "manager_params",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("cluster_manager_id");

=head1 RELATIONS

=head2 cluster

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Cluster>

=cut

__PACKAGE__->belongs_to(
  "cluster",
  "AdministratorDB::Schema::Result::Cluster",
  { cluster_id => "cluster_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 manager_param

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ParamPreset>

=cut

__PACKAGE__->belongs_to(
  "manager_param",
  "AdministratorDB::Schema::Result::ParamPreset",
  { param_preset_id => "manager_params" },
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-05-31 14:26:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:izR0W9e2SHMy3Hcb22maFw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
