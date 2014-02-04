use utf8;
package Kanopya::Schema::Result::KanopyaExecutor;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::KanopyaExecutor

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

=head2 control_queue

  data_type: 'char'
  is_nullable: 1
  size: 255

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

=head2 private_directory

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
  "control_queue",
  { data_type => "char", is_nullable => 1, size => 255 },
  "time_step",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "masterimages_directory",
  { data_type => "char", is_nullable => 0, size => 255 },
  "clusters_directory",
  { data_type => "char", is_nullable => 0, size => 255 },
  "private_directory",
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

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "kanopya_executor",
  "Kanopya::Schema::Result::Component",
  { component_id => "kanopya_executor_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-01-30 17:59:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FieQPKeaNfIiuwz6a+tuIw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
