package AdministratorDB::Schema::Result::Pleskpanel10;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Pleskpanel10

=cut

__PACKAGE__->table("pleskpanel10");

=head1 ACCESSORS

=head2 component_instance_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 pleskpanel10_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 pleskpanel10_hostname

  data_type: 'char'
  default_value: 'hostname'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "component_instance_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "pleskpanel10_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "pleskpanel10_hostname",
  {
    data_type => "char",
    default_value => "hostname",
    is_nullable => 0,
    size => 32,
  },
);
__PACKAGE__->set_primary_key("pleskpanel10_id");

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


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-04-15 16:34:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ejsRyP78va3clME0NwE2LQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
