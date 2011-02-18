package AdministratorDB::Schema::Result::Syslogng3;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Syslogng3

=cut

__PACKAGE__->table("syslogng3");

=head1 ACCESSORS

=head2 syslogng3_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 component_instance_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "syslogng3_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "component_instance_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("syslogng3_id");

=head1 RELATIONS

=head2 component_instance

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ComponentInstance>

=cut

__PACKAGE__->belongs_to(
  "component_instance",
  "AdministratorDB::Schema::Result::ComponentInstance",
  { component_instance_id => "component_instance_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 syslogng3_entries

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Syslogng3Entry>

=cut

__PACKAGE__->has_many(
  "syslogng3_entries",
  "AdministratorDB::Schema::Result::Syslogng3Entry",
  { "foreign.syslogng3_id" => "self.syslogng3_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 syslogng3_logs

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Syslogng3Log>

=cut

__PACKAGE__->has_many(
  "syslogng3_logs",
  "AdministratorDB::Schema::Result::Syslogng3Log",
  { "foreign.syslogng3_id" => "self.syslogng3_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+8hvOSY3CZ3kWp78EP7K5Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
