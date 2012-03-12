package AdministratorDB::Schema::Result::NetappVolumeManager;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::NetappVolumeManager

=cut

__PACKAGE__->table("netapp_volume_manager");

=head1 ACCESSORS

=head2 netapp_volume_manager_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "netapp_volume_manager_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("netapp_volume_manager_id");


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-03-11 21:47:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wp9W7GAEOmcl1xuvG4xH5A

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Connector",
    { "foreign.connector_id" => "self.netapp_volume_manager_id" },
    { cascade_copy => 0, cascade_delete => 1 }
);

# You can replace this text with custom content, and it will be preserved on regeneration
1;
