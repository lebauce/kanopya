use utf8;
package AdministratorDB::Schema::Result::Keepalived1Vrrpinstance;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Keepalived1Vrrpinstance

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

=head1 TABLE: C<keepalived1_vrrpinstance>

=cut

__PACKAGE__->table("keepalived1_vrrpinstance");

=head1 ACCESSORS

=head2 vrrpinstance_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 keepalived_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 vrrpinstance_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 vrrpinstance_password

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 interface_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "vrrpinstance_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "keepalived_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "vrrpinstance_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "vrrpinstance_password",
  { data_type => "char", is_nullable => 0, size => 32 },
  "interface_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</vrrpinstance_id>

=back

=cut

__PACKAGE__->set_primary_key("vrrpinstance_id");

=head1 RELATIONS

=head2 interface

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Interface>

=cut

__PACKAGE__->belongs_to(
  "interface",
  "AdministratorDB::Schema::Result::Interface",
  { interface_id => "interface_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 keepalived

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Keepalived1>

=cut

__PACKAGE__->belongs_to(
  "keepalived",
  "AdministratorDB::Schema::Result::Keepalived1",
  { keepalived_id => "keepalived_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 keepalived1_virtualips

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Keepalived1Virtualip>

=cut

__PACKAGE__->has_many(
  "keepalived1_virtualips",
  "AdministratorDB::Schema::Result::Keepalived1Virtualip",
  { "foreign.vrrpinstance_id" => "self.vrrpinstance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-03 17:00:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+eJsRRriEIsBNbF3f92wOw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
