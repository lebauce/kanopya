package AdministratorDB::Schema::Result::Haproxy1;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::IntrospectableM2M';

use base qw/DBIx::Class::Core/;

=head1 NAME

AdministratorDB::Schema::Result::Haproxy1

=cut

__PACKAGE__->table("haproxy1");

=head1 ACCESSORS

=head2 haproxy1_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "haproxy1_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("haproxy1_id");

=head1 RELATIONS

=head2 haproxy1

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "haproxy1",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "haproxy1_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 haproxy1s_listen

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Haproxy1Listen>

=cut

__PACKAGE__->has_many(
  "haproxy1s_listen",
  "AdministratorDB::Schema::Result::Haproxy1Listen",
  { "foreign.haproxy1_id" => "self.haproxy1_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-05-31 15:25:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NwviNIQSSrd6SSBl0srjFg

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Component",
    { "foreign.component_id" => "self.haproxy1_id" },
    { cascade_copy => 0, cascade_delete => 1 });

=head2 haproxy1_listens

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Haproxy1Listen>

Created to be used instead of confusing haproxy1s_listen relationships
(conflicting with the same relationship name in Component)

=cut

__PACKAGE__->has_many(
  "haproxy1_listens",
  "AdministratorDB::Schema::Result::Haproxy1Listen",
  { "foreign.haproxy1_id" => "self.haproxy1_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
