package AdministratorDB::Schema::Result::Iscsitarget1;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Iscsitarget1

=cut

__PACKAGE__->table("iscsitarget1");

=head1 ACCESSORS

=head2 iscsitarget1_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "iscsitarget1_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("iscsitarget1_id");

=head1 RELATIONS

=head2 iscsitarget1

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "iscsitarget1",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "iscsitarget1_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-04-23 10:07:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XZucU0CkJT/oQDbkUO3MBg

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Component",
    { "foreign.component_id" => "self.iscsitarget1_id" },
    { cascade_copy => 0, cascade_delete => 1 }
);

1;
