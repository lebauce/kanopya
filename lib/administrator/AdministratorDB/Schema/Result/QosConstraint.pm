package AdministratorDB::Schema::Result::QosConstraint;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::QosConstraint

=cut

__PACKAGE__->table("qos_constraint");

=head1 ACCESSORS

=head2 constraint_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 constraint_max_latency

  data_type: 'integer'
  is_nullable: 0

=head2 constraint_max_abort_rate

  data_type: 'integer'
  is_nullable: 0

=head2 cluster_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "constraint_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "constraint_max_latency",
  { data_type => "integer", is_nullable => 0 },
  "constraint_max_abort_rate",
  { data_type => "integer", is_nullable => 0 },
  "cluster_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("constraint_id");

=head1 RELATIONS

=head2 cluster

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Cluster>

=cut

__PACKAGE__->belongs_to(
  "cluster",
  "AdministratorDB::Schema::Result::Cluster",
  { cluster_id => "cluster_id" },
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-04-26 14:21:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+erDllOfIBjC2SoFAYc+Aw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
