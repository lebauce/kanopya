package AdministratorDB::Schema::Result::HAProxy1;

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::HAProxy1

=cut

__PACKAGE__->table("haproxy1");

=head1 ACCESSORS

=head2 haproxy1_id

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
  "haproxy1_id",
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

1;
