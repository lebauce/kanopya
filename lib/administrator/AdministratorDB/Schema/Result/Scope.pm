use utf8;
package AdministratorDB::Schema::Result::Scope;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Scope

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<scope>

=cut

__PACKAGE__->table("scope");

=head1 ACCESSORS

=head2 scope_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 scope_name

  data_type: 'char'
  is_nullable: 0
  size: 64

=cut

__PACKAGE__->add_columns(
  "scope_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "scope_name",
  { data_type => "char", is_nullable => 0, size => 64 },
);

=head1 PRIMARY KEY

=over 4

=item * L</scope_id>

=back

=cut

__PACKAGE__->set_primary_key("scope_id");

=head1 RELATIONS

=head2 scope_parameters

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ScopeParameter>

=cut

__PACKAGE__->has_many(
  "scope_parameters",
  "AdministratorDB::Schema::Result::ScopeParameter",
  { "foreign.scope_id" => "self.scope_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-06-07 17:07:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Y0SKkIwyPPa8/9clDJfEYQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
