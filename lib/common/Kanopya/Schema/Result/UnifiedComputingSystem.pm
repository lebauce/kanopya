use utf8;
package Kanopya::Schema::Result::UnifiedComputingSystem;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::UnifiedComputingSystem

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

Related object: L<Kanopya::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "uc",
  "Kanopya::Schema::Result::ServiceProvider",
  { service_provider_id => "ucs_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DPbRiX79MJefMdQNvBTHZA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
