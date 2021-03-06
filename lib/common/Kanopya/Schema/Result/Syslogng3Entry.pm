use utf8;
package Kanopya::Schema::Result::Syslogng3Entry;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Syslogng3Entry

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

=head1 TABLE: C<syslogng3_entry>

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

=head1 PRIMARY KEY

=over 4

=item * L</syslogng3_entry_id>

=back

=cut

__PACKAGE__->set_primary_key("syslogng3_entry_id");

=head1 RELATIONS

=head2 syslogng3

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Syslogng3>

=cut

__PACKAGE__->belongs_to(
  "syslogng3",
  "Kanopya::Schema::Result::Syslogng3",
  { syslogng3_id => "syslogng3_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 syslogng3_entry_params

Type: has_many

Related object: L<Kanopya::Schema::Result::Syslogng3EntryParam>

=cut

__PACKAGE__->has_many(
  "syslogng3_entry_params",
  "Kanopya::Schema::Result::Syslogng3EntryParam",
  { "foreign.syslogng3_entry_id" => "self.syslogng3_entry_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jSZE6R5Ln+nGmFMVIMbnFg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
