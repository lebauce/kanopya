package AdministratorDB::Schema::Result::Mysql5;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Mysql5

=cut

__PACKAGE__->table("mysql5");

=head1 ACCESSORS

=head2 mysql5_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 component_instance_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 mysql5_port

  data_type: 'integer'
  default_value: 3306
  extra: {unsigned => 1}
  is_nullable: 0

=head2 mysql5_datadir

  data_type: 'char'
  default_value: '/var/lib/mysql'
  is_nullable: 0
  size: 64

=head2 mysql5_bindaddress

  data_type: 'char'
  default_value: '127.0.0.1'
  is_nullable: 0
  size: 17

=cut

__PACKAGE__->add_columns(
  "mysql5_id",
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
  "mysql5_port",
  {
    data_type => "integer",
    default_value => 3306,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "mysql5_datadir",
  {
    data_type => "char",
    default_value => "/var/lib/mysql",
    is_nullable => 0,
    size => 64,
  },
  "mysql5_bindaddress",
  {
    data_type => "char",
    default_value => "127.0.0.1",
    is_nullable => 0,
    size => 17,
  },
);
__PACKAGE__->set_primary_key("mysql5_id");

=head1 RELATIONS

=head2 component_instance

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ComponentInstance>

=cut

__PACKAGE__->belongs_to(
  "component_instance",
  "AdministratorDB::Schema::Result::ComponentInstance",
  { component_instance_id => "component_instance_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-25 14:17:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GjHNjKWDVaO20LikdVGI8w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
