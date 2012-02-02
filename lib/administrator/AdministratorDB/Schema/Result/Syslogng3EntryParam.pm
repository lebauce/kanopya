package AdministratorDB::Schema::Result::Syslogng3EntryParam;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Syslogng3EntryParam

=cut

__PACKAGE__->table("syslogng3_entry_param");

=head1 ACCESSORS

=head2 syslogng3_entry_param_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 syslogng3_entry_param_content

  data_type: 'text'
  is_nullable: 0

=head2 syslogng3_entry_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "syslogng3_entry_param_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "syslogng3_entry_param_content",
  { data_type => "text", is_nullable => 0 },
  "syslogng3_entry_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("syslogng3_entry_param_id");

=head1 RELATIONS

=head2 syslogng3_entry

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Syslogng3Entry>

=cut

__PACKAGE__->belongs_to(
  "syslogng3_entry",
  "AdministratorDB::Schema::Result::Syslogng3Entry",
  { syslogng3_entry_id => "syslogng3_entry_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-25 14:17:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Z43FhK6OBXvEVIGsqITjoQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
