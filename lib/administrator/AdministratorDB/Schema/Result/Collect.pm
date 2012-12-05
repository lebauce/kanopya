package AdministratorDB::Schema::Result::Collect;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Collect

=cut

__PACKAGE__->table("collect");

=head1 ACCESSORS

=head2 indicatorset_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 service_provider_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "indicatorset_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "service_provider_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("indicatorset_id", "service_provider_id");

=head1 RELATIONS

=head2 indicatorset

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Indicatorset>

=cut

__PACKAGE__->belongs_to(
  "indicatorset",
  "AdministratorDB::Schema::Result::Indicatorset",
  { indicatorset_id => "indicatorset_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-25 14:17:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kWp14rSbpS2VfwDHzHxVcQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
