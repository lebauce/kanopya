use utf8;
package AdministratorDB::Schema::Result::KanopyaExecutor;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::KanopyaExecutor

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<DBIx::Class::IntrospectableM2M>

=cut

use base 'DBIx::Class::IntrospectableM2M';

=head1 LEFT BASE CLASSES

=over 4

=item * L<DBIx::Class::Core>

=back

=cut

use base qw/DBIx::Class::Core/;

=head1 TABLE: C<kanopya_executor>

=cut

__PACKAGE__->table("kanopya_executor");

=head1 ACCESSORS

=head2 kanopya_executor_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 time_step

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 masterimages_directory

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 clusters_directory

  data_type: 'char'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "kanopya_executor_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "time_step",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "masterimages_directory",
  { data_type => "char", is_nullable => 0, size => 255 },
  "clusters_directory",
  { data_type => "char", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</kanopya_executor_id>

=back

=cut

__PACKAGE__->set_primary_key("kanopya_executor_id");

=head1 RELATIONS

=head2 kanopya_executor

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "kanopya_executor",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "kanopya_executor_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2013-03-28 12:35:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kySu35+UBr8s6xRkXufVqw

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "kanopya_executor_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
