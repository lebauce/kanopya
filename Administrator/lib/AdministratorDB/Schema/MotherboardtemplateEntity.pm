package AdministratorDB::Schema::MotherboardtemplateEntity;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("motherboardtemplate_entity");
__PACKAGE__->add_columns(
  "entity_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "motherboardtemplate_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("entity_id", "motherboardtemplate_id");


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-07-14 20:51:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2u1Nf4HW39O5gi4Z847wug


# You can replace this text with custom content, and it will be preserved on regeneration
1;
