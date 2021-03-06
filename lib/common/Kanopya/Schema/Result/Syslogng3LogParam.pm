use utf8;
package Kanopya::Schema::Result::Syslogng3LogParam;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Syslogng3LogParam

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<DBIx::Class::IntrospectableM2M>

=cut

use base 'DBIx::Class::IntrospectableM2M';

=head1 LEFT BASE CLASSES

=over 4

=item * L<DBIx::Class::Core>

=back

=cut

use base qw/DBIx::Class::Core/;

=head1 TABLE: C<syslogng3_log_param>

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

=head1 PRIMARY KEY

=over 4

=item * L</syslogng3_log_param_id>

=back

=cut

__PACKAGE__->set_primary_key("syslogng3_log_param_id");

=head1 RELATIONS

=head2 syslogng3_log

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Syslogng3Log>

=cut

__PACKAGE__->belongs_to(
  "syslogng3_log",
  "Kanopya::Schema::Result::Syslogng3Log",
  { syslogng3_log_id => "syslogng3_log_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:a2bDv69Oga9SnAiEKRovAg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
