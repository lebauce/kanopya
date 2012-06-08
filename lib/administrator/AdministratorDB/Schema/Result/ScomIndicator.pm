use utf8;
package AdministratorDB::Schema::Result::ScomIndicator;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::ScomIndicator

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<scom_indicator>

=cut

__PACKAGE__->table("scom_indicator");

=head1 ACCESSORS

=head2 scom_indicator_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 scom_indicator_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 scom_indicator_oid

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 scom_indicator_min

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 scom_indicator_max

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 scom_indicator_unit

  data_type: 'char'
  is_nullable: 1
  size: 15

=head2 service_provider_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "scom_indicator_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "scom_indicator_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "scom_indicator_oid",
  { data_type => "char", is_nullable => 0, size => 64 },
  "scom_indicator_min",
  { data_type => "bigint", extra => { unsigned => 1 }, is_nullable => 1 },
  "scom_indicator_max",
  { data_type => "bigint", extra => { unsigned => 1 }, is_nullable => 1 },
  "scom_indicator_unit",
  { data_type => "char", is_nullable => 1, size => 15 },
  "service_provider_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</scom_indicator_id>

=back

=cut

__PACKAGE__->set_primary_key("scom_indicator_id");

=head1 RELATIONS

=head2 service_provider

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "service_provider",
  "AdministratorDB::Schema::Result::ServiceProvider",
  { service_provider_id => "service_provider_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-06-07 18:42:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ARuX/IL0uFQLna7G7ehRDg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
