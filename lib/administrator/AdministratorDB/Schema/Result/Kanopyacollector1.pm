package AdministratorDB::Schema::Result::Kanopyacollector1;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Kanopyacollector1

=cut

__PACKAGE__->table("kanopyacollector1");

=head1 ACCESSORS

=head2 kanopyacollector1_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 kanopyacollector1_collect_frequency

  data_type: 'integer'
  default_value: 3600
  extra: {unsigned => 1}
  is_nullable: 0

=head2 kanopyacollector1_storage_time

  data_type: 'integer'
  default_value: 86400
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "kanopyacollector1_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "kanopyacollector1_collect_frequency",
  {
    data_type => "integer",
    default_value => 3600,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "kanopyacollector1_storage_time",
  {
    data_type => "integer",
    default_value => 86400,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("kanopyacollector1_id");

=head1 RELATIONS

=head2 kanopyacollector1

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "kanopyacollector1",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "kanopyacollector1_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-05-04 12:06:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:T9QCpNR2pRLHRR5sFRTGNQ


# You can replace this text with custom content, and it will be preserved on regeneration

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Component",
    { "foreign.component_id" => "self.kanopyacollector1_id" },
    { cascade_copy => 0, cascade_delete => 1 }
);

1;
