use utf8;
package AdministratorDB::Schema::Result::HpcManager;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::HpcManager

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

=head1 TABLE: C<hpc_manager>

=cut

__PACKAGE__->table("hpc_manager");

=head1 ACCESSORS

=head2 hpc_manager_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 virtualconnect_ip

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 bladesystem_ip

  data_type: 'char'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "hpc_manager_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "virtualconnect_ip",
  { data_type => "char", is_nullable => 1, size => 255 },
  "bladesystem_ip",
  { data_type => "char", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</hpc_manager_id>

=back

=cut

__PACKAGE__->set_primary_key("hpc_manager_id");

=head1 RELATIONS

=head2 hpc_manager

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "hpc_manager",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "hpc_manager_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 12:11:03
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/MS6K0XQiBtULK5XCirDlQ

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "hpc_manager_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
