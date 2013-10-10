use utf8;
package AdministratorDB::Schema::Result::UnifiedComputingSystem;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::UnifiedComputingSystem

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

=head1 TABLE: C<unified_computing_system>

=cut

__PACKAGE__->table("unified_computing_system");

=head1 ACCESSORS

=head2 ucs_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 ucs_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 ucs_desc

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 ucs_addr

  data_type: 'char'
  is_nullable: 0
  size: 15

=head2 ucs_state

  data_type: 'char'
  default_value: 'down:0'
  is_nullable: 0
  size: 32

=head2 ucs_login

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 ucs_passwd

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 ucs_ou

  data_type: 'char'
  is_nullable: 1
  size: 32

=cut

__PACKAGE__->add_columns(
  "ucs_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "ucs_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "ucs_desc",
  { data_type => "char", is_nullable => 1, size => 255 },
  "ucs_addr",
  { data_type => "char", is_nullable => 0, size => 15 },
  "ucs_state",
  {
    data_type => "char",
    default_value => "down:0",
    is_nullable => 0,
    size => 32,
  },
  "ucs_login",
  { data_type => "char", is_nullable => 0, size => 32 },
  "ucs_passwd",
  { data_type => "char", is_nullable => 0, size => 32 },
  "ucs_ou",
  { data_type => "char", is_nullable => 1, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</ucs_id>

=back

=cut

__PACKAGE__->set_primary_key("ucs_id");

=head1 RELATIONS

=head2 uc

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "uc",
  "AdministratorDB::Schema::Result::ServiceProvider",
  { service_provider_id => "ucs_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2013-01-30 18:11:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AaIaUZj1MtbFFQn09deD5A

__PACKAGE__->belongs_to(
  "unified_computing_system",
  "AdministratorDB::Schema::Result::ServiceProvider",
  { service_provider_id => "ucs_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::ServiceProvider",
  { service_provider_id => "ucs_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
