package AdministratorDB::Schema::Result::Netapp;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Netapp

=cut

__PACKAGE__->table("netapp");

=head1 ACCESSORS

=head2 netapp_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 netapp_name
 
   data_type: 'char'
   is_nullable: 0
   size: 32
 
=head2 netapp_desc
 
   data_type: 'char'
   is_nullable: 1
   size: 255
 
=head2 netapp_addr
 
   data_type: 'char'
   is_nullable: 0
   size: 15
 
=head2 netapp_login
 
   data_type: 'char'
   is_nullable: 0
   size: 32
 
=head2 netapp_passwd
 
   data_type: 'char'
   is_nullable: 0
   size: 32

=cut

__PACKAGE__->add_columns(
  "netapp_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "netapp_name",
  { 
    data_type => "char",
    is_nullable => 0, size => 32,
  },
  "netapp_desc",
  { 
    data_type => "char", 
    is_nullable => 1,
    size => 255,
  },
  "netapp_addr",
  { 
    data_type => "char",
    is_nullable => 0,
    size => 15,
  },
  "netapp_login",
  { 
    data_type => "char",
    is_nullable => 0,
    size => 32,
  },
  "netapp_passwd",
  {
    data_type => "char",
    is_nullable => 0,
    size => 32,
  },
);
__PACKAGE__->set_primary_key("netapp_id");

=head1 RELATIONS

=head2 netapp

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Outside>

=cut

__PACKAGE__->belongs_to(
  "netapp",
  "AdministratorDB::Schema::Result::Outside",
  { outside_id => "netapp_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-02-02 10:20:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LHxtKXtQ0vdLBfBHxkjBAA

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Outside",
    { "foreign.outside_id" => "self.netapp_id" },
    { cascade_copy => 0, cascade_delete => 1 });

1;
