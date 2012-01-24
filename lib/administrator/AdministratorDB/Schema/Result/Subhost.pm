package AdministratorDB::Schema::Result::Subhost;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Subhost

=cut

__PACKAGE__->table("subhost");

=head1 ACCESSORS

=head2 subhost_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 subhost_attr

  data_type: 'char'
  is_nullable: 0
  size: 128

=cut

__PACKAGE__->add_columns(
  "subhost_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "subhost_attr",
  { data_type => "char", is_nullable => 0, size => 128 },
);
__PACKAGE__->set_primary_key("subhost_id");

=head1 RELATIONS

=head2 subhost

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Host>

=cut

__PACKAGE__->belongs_to(
  "subhost",
  "AdministratorDB::Schema::Result::Host",
  { host_id => "subhost_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-24 12:05:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UQzJ1FLoEK/L8weBfXAMtA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Host",
    { "foreign.host_id" => "self.subhost_id" },
    { cascade_copy => 0, cascade_delete => 1 });

1;
