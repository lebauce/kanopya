package AdministratorDB::Schema::Result::Syslogng3Entry;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Syslogng3Entry

=cut

__PACKAGE__->table("syslogng3_entry");

=head1 ACCESSORS

=head2 syslogng3_entry_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 syslogng3_entry_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 syslogng3_entry_type

  data_type: 'enum'
  extra: {list => ["source","destination","filter"]}
  is_nullable: 0

=head2 syslogng3_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "syslogng3_entry_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "syslogng3_entry_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "syslogng3_entry_type",
  {
    data_type => "enum",
    extra => { list => ["source", "destination", "filter"] },
    is_nullable => 0,
  },
  "syslogng3_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("syslogng3_entry_id");

=head1 RELATIONS

=head2 syslogng3

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Syslogng3>

=cut

__PACKAGE__->belongs_to(
  "syslogng3",
  "AdministratorDB::Schema::Result::Syslogng3",
  { syslogng3_id => "syslogng3_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 syslogng3_entry_params

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Syslogng3EntryParam>

=cut

__PACKAGE__->has_many(
  "syslogng3_entry_params",
  "AdministratorDB::Schema::Result::Syslogng3EntryParam",
  { "foreign.syslogng3_entry_id" => "self.syslogng3_entry_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JxvXUoPhqe0c8v6UenWj9w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
