package AdministratorDB::Schema::Result::Keepalived1;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::IntrospectableM2M';

use base qw/DBIx::Class::Core/;

=head1 NAME

AdministratorDB::Schema::Result::Keepalived1

=cut

__PACKAGE__->table("keepalived1");

=head1 ACCESSORS

=head2 keepalived_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 notification_email

  data_type: 'char'
  default_value: 'admin@hedera-technology.com'
  is_nullable: 0
  size: 255

=head2 smtp_server

  data_type: 'char'
  is_nullable: 0
  size: 39

=cut

__PACKAGE__->add_columns(
  "keepalived_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "notification_email",
  {
    data_type => "char",
    default_value => "admin\@hedera-technology.com",
    is_nullable => 0,
    size => 255,
  },
  "smtp_server",
  { data_type => "char", is_nullable => 0, size => 39 },
);
__PACKAGE__->set_primary_key("keepalived_id");

=head1 RELATIONS

=head2 keepalived

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "keepalived",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "keepalived_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 keepalived1_vrrpinstances

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Keepalived1Vrrpinstance>

=cut

__PACKAGE__->has_many(
  "keepalived1_vrrpinstances",
  "AdministratorDB::Schema::Result::Keepalived1Vrrpinstance",
  { "foreign.keepalived_id" => "self.keepalived_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-05-30 10:47:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HyVobdrHXK43gGADrU4PBg

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Component",
    { "foreign.component_id" => "self.keepalived_id" },
    { cascade_copy => 0, cascade_delete => 1 });

1;
