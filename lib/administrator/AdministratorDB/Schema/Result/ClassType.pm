package AdministratorDB::Schema::Result::ClassType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::ClassType

=cut

__PACKAGE__->table("class_type");

=head1 ACCESSORS

=head2 class_type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 class_type

  data_type: 'char'
  is_nullable: 0
  size: 64

=cut

__PACKAGE__->add_columns(
  "class_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "class_type",
  { data_type => "char", is_nullable => 0, size => 64 },
);
__PACKAGE__->set_primary_key("class_type_id");

=head1 RELATIONS

=head2 entities

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->has_many(
  "entities",
  "AdministratorDB::Schema::Result::Entity",
  { "foreign.class_type_id" => "self.class_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-02-23 16:57:03
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4wb049xlwCIA4jkQQ5JbYA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
