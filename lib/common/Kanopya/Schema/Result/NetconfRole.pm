use utf8;
package Kanopya::Schema::Result::NetconfRole;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::NetconfRole

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

=head1 TABLE: C<netconf_role>

=cut

__PACKAGE__->table("netconf_role");

=head1 ACCESSORS

=head2 netconf_role_id

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 netconf_role_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "netconf_role_id",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "netconf_role_name",
  { data_type => "char", is_nullable => 0, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</netconf_role_id>

=back

=cut

__PACKAGE__->set_primary_key("netconf_role_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<netconf_role_name>

=over 4

=item * L</netconf_role_name>

=back

=cut

__PACKAGE__->add_unique_constraint("netconf_role_name", ["netconf_role_name"]);

=head1 RELATIONS

=head2 netconf_role

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "netconf_role",
  "Kanopya::Schema::Result::Entity",
  { entity_id => "netconf_role_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 netconfs

Type: has_many

Related object: L<Kanopya::Schema::Result::Netconf>

=cut

__PACKAGE__->has_many(
  "netconfs",
  "Kanopya::Schema::Result::Netconf",
  { "foreign.netconf_role_id" => "self.netconf_role_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-03-03 12:34:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:z0oh9mPWuUpGgiu/J11QqQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
