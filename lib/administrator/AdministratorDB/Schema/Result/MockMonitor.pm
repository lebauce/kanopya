package AdministratorDB::Schema::Result::MockMonitor;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::MockMonitor

=cut

__PACKAGE__->table("mock_monitor");

=head1 ACCESSORS

=head2 mock_monitor_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "mock_monitor_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("mock_monitor_id");

=head1 RELATIONS

=head2 mock_monitor

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Connector>

=cut

__PACKAGE__->belongs_to(
  "mock_monitor",
  "AdministratorDB::Schema::Result::Connector",
  { connector_id => "mock_monitor_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-05-31 15:58:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:10A9OpEsLhvCPOnkvW4u4A

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Connector",
    { "foreign.connector_id" => "self.mock_monitor_id" },
    { cascade_copy => 0, cascade_delete => 1 });

1;
