use utf8;
package AdministratorDB::Schema::Result::ScopeParameter;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::ScopeParameter

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<scope_parameter>

=cut

__PACKAGE__->table("scope_parameter");

=head1 ACCESSORS

=head2 scope_parameter_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
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

=cut

__PACKAGE__->add_columns(
  "scope_parameter_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "scope_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "scope_parameter_name",
  { data_type => "char", is_nullable => 0, size => 64 },
);

=head1 PRIMARY KEY

=over 4

=item * L</scope_parameter_id>

=back

=cut

__PACKAGE__->set_primary_key("scope_parameter_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<scope_id>

=over 4

=item * L</scope_id>

=item * L</scope_parameter_name>

=back

=cut

__PACKAGE__->add_unique_constraint("scope_id", ["scope_id", "scope_parameter_name"]);

=head1 RELATIONS

=head2 scope

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Scope>

=cut

__PACKAGE__->belongs_to(
  "scope",
  "AdministratorDB::Schema::Result::Scope",
  { scope_id => "scope_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-06-07 17:07:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wFj6kiBZaAHdSTGjRumZ3w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
