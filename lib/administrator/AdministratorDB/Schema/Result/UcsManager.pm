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

=head2 ucs

Type: belongs_to

=cut

__PACKAGE__->belongs_to(
  "ucs",
  "AdministratorDB::Schema::Result::Connector",
  { connector_id => "ucs_manager_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-02-24 10:51:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qWYJTCsbqQZE1kFxKazsKw

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Connector",
    { "foreign.connector_id" => "self.ucs_manager_id" },
    { cascade_copy => 0, cascade_delete => 1 }
);

# You can replace this text with custom content, and it will be preserved on regeneration
1;
