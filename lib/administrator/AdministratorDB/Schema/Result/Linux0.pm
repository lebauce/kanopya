package AdministratorDB::Schema::Result::Linux0;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Linux0

=cut

__PACKAGE__->table("linux0");

=head1 ACCESSORS

=head2 linux0_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "linux0_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("linux0_id");

=head1 RELATIONS

=head2 linux0

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "linux0",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "linux0_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 linux0s_mount

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Linux0Mount>

=cut

__PACKAGE__->has_many(
  "linux0s_mount",
  "AdministratorDB::Schema::Result::Linux0Mount",
  { "foreign.linux0_id" => "self.linux0_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-05-28 11:11:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dwDENA8EGYqxIHNtAEGJkw


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Component",
        { "foreign.component_id" => "self.linux0_id" },
        { cascade_copy => 0, cascade_delete => 1 });

1;
