package AdministratorDB::Schema::Result::Rule;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Rule

=cut

__PACKAGE__->table("rule");

=head1 ACCESSORS

=head2 rule_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 rule_condition

  data_type: 'char'
  is_nullable: 0
  size: 128

=head2 rule_action

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 cluster_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "rule_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "rule_condition",
  { data_type => "char", is_nullable => 0, size => 128 },
  "rule_action",
  { data_type => "char", is_nullable => 0, size => 32 },
  "cluster_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("rule_id");

=head1 RELATIONS

=head2 cluster

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Cluster>

=cut

__PACKAGE__->belongs_to(
  "cluster",
  "AdministratorDB::Schema::Result::Cluster",
  { cluster_id => "cluster_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 ruleconditions

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Rulecondition>

=cut

__PACKAGE__->has_many(
  "ruleconditions",
  "AdministratorDB::Schema::Result::Rulecondition",
  { "foreign.rule_id" => "self.rule_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-25 14:17:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:V6zmljaGJXBHPHvxFP0sbA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
