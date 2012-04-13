package AdministratorDB::Schema::Result::Server;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Server

=cut

__PACKAGE__->table("server");

=head1 ACCESSORS

=head2 server_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "server_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("server_id");

=head1 RELATIONS

=head2 server

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Inside>

=cut

__PACKAGE__->belongs_to(
  "server",
  "AdministratorDB::Schema::Result::Inside",
  { inside_id => "server_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-02-02 10:20:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:c6sOoo9uJjmop7v9SHVm6A

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Inside",
    { "foreign.inside_id" => "self.server_id" },
    { cascade_copy => 0, cascade_delete => 1 });

1;
