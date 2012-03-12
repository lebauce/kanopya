package AdministratorDB::Schema::Result::Fileimagemanager0;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Fileimagemanager0

=cut

__PACKAGE__->table("fileimagemanager0");

=head1 ACCESSORS

=head2 fileimagemanager0_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "fileimagemanager0_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("fileimagemanager0_id");

=head1 RELATIONS

=head2 fileimagemanager0

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "fileimagemanager0",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "fileimagemanager0_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-03-06 14:51:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LLG9gcIQctJ7RAq9oI72Fw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Component",
    { "foreign.component_id" => "self.fileimagemanager0_id" },
    { cascade_copy => 0, cascade_delete => 1 });
1;
