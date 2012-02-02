package AdministratorDB::Schema::Result::Haproxy1;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Haproxy1

=cut

__PACKAGE__->table("haproxy1");

=head1 ACCESSORS

=head2 haproxy1_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 haproxy1_http_frontend_port

  data_type: 'integer'
  is_nullable: 0

=head2 haproxy1_http_backend_port

  data_type: 'integer'
  is_nullable: 0

=head2 haproxy1_https_frontend_port

  data_type: 'integer'
  is_nullable: 0

=head2 haproxy1_https_backend_port

  data_type: 'integer'
  is_nullable: 0

=head2 haproxy1_log_server_address

  data_type: 'char'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "haproxy1_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "haproxy1_http_frontend_port",
  { data_type => "integer", is_nullable => 0 },
  "haproxy1_http_backend_port",
  { data_type => "integer", is_nullable => 0 },
  "haproxy1_https_frontend_port",
  { data_type => "integer", is_nullable => 0 },
  "haproxy1_https_backend_port",
  { data_type => "integer", is_nullable => 0 },
  "haproxy1_log_server_address",
  { data_type => "char", is_nullable => 0, size => 32 },
);
__PACKAGE__->set_primary_key("haproxy1_id");

=head1 RELATIONS

=head2 haproxy1

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "haproxy1",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "haproxy1_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-26 17:01:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uWDMW6kj3jlh4aoolObFuA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Component",
    { "foreign.component_id" => "self.haproxy1_id" },
    { cascade_copy => 0, cascade_delete => 1 });
1;
