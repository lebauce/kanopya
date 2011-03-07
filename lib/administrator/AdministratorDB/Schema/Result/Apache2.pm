package AdministratorDB::Schema::Result::Apache2;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Apache2

=cut

__PACKAGE__->table("apache2");

=head1 ACCESSORS

=head2 component_instance_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 apache2_serverroot

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 apache2_loglevel

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 apache2_ports

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 apache2_sslports

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 apache2_phpsession_dir

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 apache2_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "component_instance_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "apache2_serverroot",
  { data_type => "char", is_nullable => 0, size => 64 },
  "apache2_loglevel",
  { data_type => "char", is_nullable => 0, size => 64 },
  "apache2_ports",
  { data_type => "char", is_nullable => 0, size => 32 },
  "apache2_sslports",
  { data_type => "char", is_nullable => 0, size => 32 },
  "apache2_phpsession_dir",
  { data_type => "char", is_nullable => 0, size => 64 },
  "apache2_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("apache2_id");

=head1 RELATIONS

=head2 component_instance

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ComponentInstance>

=cut

__PACKAGE__->belongs_to(
  "component_instance",
  "AdministratorDB::Schema::Result::ComponentInstance",
  { component_instance_id => "component_instance_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 apache2_virtualhosts

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Apache2Virtualhost>

=cut

__PACKAGE__->has_many(
  "apache2_virtualhosts",
  "AdministratorDB::Schema::Result::Apache2Virtualhost",
  { "foreign.apache2_id" => "self.apache2_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:t14ZsY0+sYfzilOy0ZU90Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
