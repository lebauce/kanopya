package AdministratorDB::Schema::Result::ScopeParameter;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::ScopeParameter

=cut

__PACKAGE__->table("scope_parameter");

=head1 ACCESSORS

=head2 scope_parameter_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 scope_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 scope_parameter_name

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 class_type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "scope_parameter_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "scope_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "scope_parameter_name",
  { data_type => "char", is_nullable => 0, size => 64 },
  "class_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("scope_parameter_id");
__PACKAGE__->add_unique_constraint("scope_id", ["scope_id", "scope_parameter_name"]);

=head1 RELATIONS

=head2 class_type

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ClassType>

=cut

__PACKAGE__->belongs_to(
  "class_type",
  "AdministratorDB::Schema::Result::ClassType",
  { class_type_id => "class_type_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 scope

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Scope>

=cut

__PACKAGE__->belongs_to(
  "scope",
  "AdministratorDB::Schema::Result::Scope",
  { scope_id => "scope_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-05-30 14:27:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dCFb3PzGW9PsLEsxwK8wjw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
