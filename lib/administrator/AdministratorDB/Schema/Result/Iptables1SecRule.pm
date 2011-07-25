package AdministratorDB::Schema::Result::Iptables1SecRule;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Iptables1SecRule

=cut

__PACKAGE__->table("iptables1_sec_rule");

=head1 ACCESSORS

=head2 iptables1_sec_rule_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 component_instance_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 iptables1_sec_rule_syn_flood

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 iptables1_sec_rule_scan_furtif

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 iptables1_sec_rule_ping_death

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 iptables1_sec_rule_anti_spoofing

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "iptables1_sec_rule_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "component_instance_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "iptables1_sec_rule_syn_flood",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "iptables1_sec_rule_scan_furtif",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "iptables1_sec_rule_ping_death",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "iptables1_sec_rule_anti_spoofing",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("iptables1_sec_rule_id");
__PACKAGE__->add_unique_constraint("fk_iptables1_sec_rule_1", ["component_instance_id"]);

=head1 RELATIONS

=head2 iptables1_components

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Iptables1Component>

=cut

__PACKAGE__->has_many(
  "iptables1_components",
  "AdministratorDB::Schema::Result::Iptables1Component",
  { "foreign.iptables1_sec_rule_id" => "self.iptables1_sec_rule_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 component_instance

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ComponentInstance>

=cut

__PACKAGE__->belongs_to(
  "component_instance",
  "AdministratorDB::Schema::Result::ComponentInstance",
  { component_instance_id => "component_instance_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-07-25 15:07:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NgvZpQXGrECQwOxEH7mdyA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
