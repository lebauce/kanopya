package AdministratorDB::Schema::Result::Lvm2;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Lvm2

=cut

__PACKAGE__->table("lvm2");

=head1 ACCESSORS

=head2 lvm2_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "lvm2_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("lvm2_id");

=head1 RELATIONS

=head2 lvm2

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "lvm2",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "lvm2_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 lvm2_vgs

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Lvm2Vg>

=cut

__PACKAGE__->has_many(
  "lvm2_vgs",
  "AdministratorDB::Schema::Result::Lvm2Vg",
  { "foreign.lvm2_id" => "self.lvm2_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-26 16:29:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WgH/JIjwl+2RMJSyCILdjg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Component",
    { "foreign.component_id" => "self.lvm2_id" },
    { cascade_copy => 0, cascade_delete => 1 });

1;
