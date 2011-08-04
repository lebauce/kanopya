package AdministratorDB::Schema::Result::Iptables1Component;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Iptables1Component

=cut

__PACKAGE__->table("iptables1_component");

=head1 ACCESSORS

=head2 iptables1_component_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 iptables1_sec_rule_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 iptables1_component_instance_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 iptables1_component_cible

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "iptables1_component_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "iptables1_sec_rule_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "iptables1_component_instance_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "iptables1_component_cible",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("iptables1_component_id");

=head1 RELATIONS

=head2 iptables1_sec_rule

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Iptables1SecRule>

=cut

__PACKAGE__->belongs_to(
  "iptables1_sec_rule",
  "AdministratorDB::Schema::Result::Iptables1SecRule",
  { iptables1_sec_rule_id => "iptables1_sec_rule_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-07-25 15:07:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:u8T1Zxq+L+sn2/N7SdyTeA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
