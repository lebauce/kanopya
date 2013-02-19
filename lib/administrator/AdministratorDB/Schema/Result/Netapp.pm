use utf8;
package AdministratorDB::Schema::Result::Netapp;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Netapp

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

=head1 TABLE: C<netapp>

=cut

__PACKAGE__->table("netapp");

=head1 ACCESSORS

=head2 netapp_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 netapp_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 netapp_desc

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 netapp_addr

  data_type: 'char'
  is_nullable: 0
  size: 15

=head2 netapp_login

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 netapp_passwd

  data_type: 'char'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "netapp_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "netapp_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "netapp_desc",
  { data_type => "char", is_nullable => 1, size => 255 },
  "netapp_addr",
  { data_type => "char", is_nullable => 0, size => 15 },
  "netapp_login",
  { data_type => "char", is_nullable => 0, size => 32 },
  "netapp_passwd",
  { data_type => "char", is_nullable => 0, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</netapp_id>

=back

=cut

__PACKAGE__->set_primary_key("netapp_id");

=head1 RELATIONS

=head2 netapp

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "netapp",
  "AdministratorDB::Schema::Result::ServiceProvider",
  { service_provider_id => "netapp_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 netapp_aggregates

Type: has_many

Related object: L<AdministratorDB::Schema::Result::NetappAggregate>

=cut

__PACKAGE__->has_many(
  "netapp_aggregates",
  "AdministratorDB::Schema::Result::NetappAggregate",
  { "foreign.netapp_id" => "self.netapp_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2013-01-30 18:11:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4QHRKD3roqOyoyb1BKlWQg

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::ServiceProvider",
  { service_provider_id => "netapp_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
