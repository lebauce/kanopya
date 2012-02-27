package AdministratorDB::Schema::Result::Externalnode;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Externalnode

=cut

__PACKAGE__->table("externalnode");

=head1 ACCESSORS

=head2 externalnode_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 externalnode_hostname

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 outside_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 externalnode_state

  data_type: 'char'
  is_nullable: 1
  size: 32

=head2 externalnode_prev_state

  data_type: 'char'
  is_nullable: 1
  size: 32

=cut

__PACKAGE__->add_columns(
  "externalnode_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "externalnode_hostname",
  { data_type => "char", is_nullable => 0, size => 255 },
  "outside_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "externalnode_state",
  { data_type => "char", is_nullable => 1, size => 32 },
  "externalnode_prev_state",
  { data_type => "char", is_nullable => 1, size => 32 },
);
__PACKAGE__->set_primary_key("externalnode_id");

=head1 RELATIONS

=head2 outside

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Outside>

=cut

__PACKAGE__->belongs_to(
  "outside",
  "AdministratorDB::Schema::Result::Outside",
  { outside_id => "outside_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-02-15 13:58:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AC44UEMarOyOj+udffEoUA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
