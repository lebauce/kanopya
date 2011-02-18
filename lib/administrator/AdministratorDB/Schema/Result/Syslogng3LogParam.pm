package AdministratorDB::Schema::Result::Syslogng3LogParam;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Syslogng3LogParam

=cut

__PACKAGE__->table("syslogng3_log_param");

=head1 ACCESSORS

=head2 syslogng3_log_param_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 syslogng3_log_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 syslogng3_log_param_entrytype

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 syslogng3_log_param_entryname

  data_type: 'char'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "syslogng3_log_param_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "syslogng3_log_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "syslogng3_log_param_entrytype",
  { data_type => "char", is_nullable => 0, size => 32 },
  "syslogng3_log_param_entryname",
  { data_type => "char", is_nullable => 0, size => 32 },
);
__PACKAGE__->set_primary_key("syslogng3_log_param_id");

=head1 RELATIONS

=head2 syslogng3_log

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Syslogng3Log>

=cut

__PACKAGE__->belongs_to(
  "syslogng3_log",
  "AdministratorDB::Schema::Result::Syslogng3Log",
  { syslogng3_log_id => "syslogng3_log_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DjO79hVzbjLbGZfDfqQZjg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
