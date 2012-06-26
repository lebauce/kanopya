package AdministratorDB::Schema::Result::Billinglimit;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Billinglimit

=cut

__PACKAGE__->table("billinglimit");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 start

  data_type: 'integer'
  is_nullable: 0

=head2 end

  data_type: 'integer'
  is_nullable: 0

=head2 type

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 soft

  data_type: 'tinyint'
  is_nullable: 0

=head2 value

  data_type: 'integer'
  is_nullable: 1

=head2 service_provider_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 repeat

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=head2 repeat_start_time

  data_type: 'time'
  is_nullable: 0

=head2 repeat_day

  data_type: 'integer'
  is_nullable: 0

=head2 repeat_end_time

  data_type: 'time'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "start",
  { data_type => "integer", is_nullable => 0 },
  "ending",
  { data_type => "integer", is_nullable => 0 },
  "type",
  { data_type => "char", is_nullable => 0, size => 32 },
  "soft",
  { data_type => "tinyint", is_nullable => 0 },
  "value",
  { data_type => "integer", is_nullable => 1 },
  "service_provider_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "repeats",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "repeat_start_time",
  { data_type => "time", is_nullable => 0 },
  "repeat_day",
  { data_type => "integer", is_nullable => 0 },
  "repeat_end_time",
  { data_type => "time", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 id

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "id",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "id" },
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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-06-04 00:42:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QN9k6A4Rumxp3i9Bv2Zpqw

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
  { "foreign.entity_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 1 }
);

1;
