package AdministratorDB::Schema::Result::Iptables1;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Iptables

=cut

__PACKAGE__->table("iptables1");

=head1 ACCESSORS

=head2 component_instance_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 iptables1_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 iptables1_tables

  data_type: 'char'
  is_nullable: 0
  size: 8

=head2 iptables1_chaine;

  data_type: 'char'
  is_nullable: 0
  size: 11

=head2 iptables1_protocole ;

  data_type: 'char'
  is_nullable: 0
  size: 11

=head2 iptables1_number_port;

  data_type: 'int'
  is_nullable: 0
  size: 6

=head2 iptables1_cible;

  data_type: 'char'
  is_nullable: 0
  size: 8

=cut

__PACKAGE__->add_columns(
  "component_instance_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "iptables1_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "iptables1_chaine",
  { data_type => "char", is_nullable => 0, size => 11},
  "iptables1_protocole",
  { data_type => "char", is_nullable => 0, size => 8 },
  
   "iptables1_number_port",
  { data_type => "int", is_nullable => 0, size => 6 },
  
   "iptables1_cible",
  { data_type => "char", is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("iptables1_id");

=head1 RELATIONS

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


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WZg9+mJaVBQI85iMvkIVAg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
