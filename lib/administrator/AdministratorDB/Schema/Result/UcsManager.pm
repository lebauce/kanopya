package AdministratorDB::Schema::Result::UcsManager;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::UcsManager

=cut

__PACKAGE__->table("ucs_manager");

=head1 ACCESSORS

=head2 ucs_manager_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "ucs_manager_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("ucs_manager_id");

=head1 RELATIONS

=head2 ucs_manager

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Connector>

=cut

__PACKAGE__->belongs_to(
  "ucs_manager",
  "AdministratorDB::Schema::Result::Connector",
  { connector_id => "ucs_manager_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-03-12 16:10:12
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yq70wXnD7sDePFGy2pugdQ


# You can replace this text with custom content, and it will be preserved on regeneration

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Connector",
    { "foreign.connector_id" => "self.ucs_manager_id" },
    { cascade_copy => 0, cascade_delete => 1 }
);

1;
