package AdministratorDB::Schema::Result::Openiscsi2;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Openiscsi2

=cut

__PACKAGE__->table("openiscsi2");

=head1 ACCESSORS

=head2 openiscsi2_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "openiscsi2_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("openiscsi2_id");

=head1 RELATIONS

=head2 openiscsi2

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "openiscsi2",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "openiscsi2_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 openiscsi2_targets

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Openiscsi2Target>

=cut

__PACKAGE__->has_many(
  "openiscsi2_targets",
  "AdministratorDB::Schema::Result::Openiscsi2Target",
  { "foreign.openiscsi2_id" => "self.openiscsi2_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-26 16:29:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vGLj9tlKi90etRmvjVN/Dw


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Component",
    { "foreign.component_id" => "self.openiscsi2_id" },
    { cascade_copy => 0, cascade_delete => 1 });
1;
