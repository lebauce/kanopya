package AdministratorDB::Schema::Result::Alert;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Alert

=cut

__PACKAGE__->table("alert");

=head1 ACCESSORS

=head2 alert_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 alert_date

  data_type: 'date'
  is_nullable: 0

=head2 alert_time

  data_type: 'time'
  is_nullable: 0

=head2 alert_message

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 alert_active

  data_type: 'integer'
  default_value: 1
  extra: {unsigned => 1}
  is_nullable: 0

=head2 entity_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 alert_signature

  data_type: 'char'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "alert_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "alert_date",
  { data_type => "date", is_nullable => 0 },
  "alert_time",
  { data_type => "time", is_nullable => 0 },
  "alert_message",
  { data_type => "char", is_nullable => 0, size => 255 },
  "alert_active",
  {
    data_type => "integer",
    default_value => 1,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "entity_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "alert_signature",
  { data_type => "char", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("alert_id");
__PACKAGE__->add_unique_constraint("alert_signature", ["alert_signature"]);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-09-07 15:48:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rXRy4UqkktfpA9/JO1h0Qw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
