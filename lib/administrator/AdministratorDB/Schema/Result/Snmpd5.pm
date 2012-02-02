package AdministratorDB::Schema::Result::Snmpd5;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Snmpd5

=cut

__PACKAGE__->table("snmpd5");

=head1 ACCESSORS

=head2 snmpd5_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 monitor_server_ip

  data_type: 'char'
  is_nullable: 0
  size: 39

=head2 snmpd_options

  data_type: 'char'
  is_nullable: 0
  size: 128

=cut

__PACKAGE__->add_columns(
  "snmpd5_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "monitor_server_ip",
  { data_type => "char", is_nullable => 0, size => 39 },
  "snmpd_options",
  { data_type => "char", is_nullable => 0, size => 128 },
);
__PACKAGE__->set_primary_key("snmpd5_id");

=head1 RELATIONS

=head2 snmpd5

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "snmpd5",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "snmpd5_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-26 16:29:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WQ1Sow0gKnQY+kgdeYcyAg


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Component",
    { "foreign.component_id" => "self.snmpd5_id" },
    { cascade_copy => 0, cascade_delete => 1 });
1;
