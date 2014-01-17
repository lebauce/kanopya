use utf8;
package Kanopya::Schema::Result::Scope;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Scope

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

Related object: L<Kanopya::Schema::Result::ScopeParameter>

=cut

__PACKAGE__->has_many(
  "scope_parameters",
  "Kanopya::Schema::Result::ScopeParameter",
  { "foreign.scope_id" => "self.scope_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Y56HsfTZSZpmgYzzIGPNgw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
