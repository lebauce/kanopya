package AdministratorDB::Schema::Result::Puppetmaster2;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Puppetmaster2

=cut

__PACKAGE__->table("puppetmaster2");

=head1 ACCESSORS

=head2 puppetmaster2_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 puppetmaster2_options

  data_type: 'char'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "puppetmaster2_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "puppetmaster2_options",
  { data_type => "char", is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("puppetmaster2_id");

=head1 RELATIONS

=head2 puppetmaster2

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "puppetmaster2",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "puppetmaster2_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-05-09 16:34:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jKcfaE2IOKUTv8K2S69/Uw

__PACKAGE__->belongs_to(
    "parent",
    "AdministratorDB::Schema::Result::Component",
    { "foreign.component_id" => "self.puppetmaster2_id" },
    { cascade_copy => 0, cascade_delete => 1 });
1;
