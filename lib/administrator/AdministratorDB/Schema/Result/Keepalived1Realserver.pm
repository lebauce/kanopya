package AdministratorDB::Schema::Result::Keepalived1Realserver;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Keepalived1Realserver

=cut

__PACKAGE__->table("keepalived1_realserver");

=head1 ACCESSORS

=head2 realserver_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 virtualserver_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 realserver_ip

  data_type: 'char'
  is_nullable: 0
  size: 39

=head2 realserver_port

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 realserver_weight

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 realserver_checkport

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 realserver_checktimeout

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "realserver_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "virtualserver_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "realserver_ip",
  { data_type => "char", is_nullable => 0, size => 39 },
  "realserver_port",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "realserver_weight",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "realserver_checkport",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "realserver_checktimeout",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("realserver_id");

=head1 RELATIONS

=head2 virtualserver

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Keepalived1Virtualserver>

=cut

__PACKAGE__->belongs_to(
  "virtualserver",
  "AdministratorDB::Schema::Result::Keepalived1Virtualserver",
  { virtualserver_id => "virtualserver_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-26 17:01:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:08eRAcLFFIDYczmFbybr+w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
