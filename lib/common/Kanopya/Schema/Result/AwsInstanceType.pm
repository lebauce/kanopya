use utf8;
package Kanopya::Schema::Result::AwsInstanceType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::AwsInstanceType

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

=head1 TABLE: C<aws_instance_type>

=cut

__PACKAGE__->table("aws_instance_type");

=head1 ACCESSORS

=head2 aws_instance_type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 ram

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 cpu

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 storage

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "aws_instance_type_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "ram",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "cpu",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "storage",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</aws_instance_type_id>

=back

=cut

__PACKAGE__->set_primary_key("aws_instance_type_id");


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2014-10-17 14:02:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iIGU2a0kt1ObH+DJJkdbdA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
