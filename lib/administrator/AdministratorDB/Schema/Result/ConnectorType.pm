package AdministratorDB::Schema::Result::ConnectorType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::ConnectorType

=cut

__PACKAGE__->table("connector_type");

=head1 ACCESSORS

=head2 connector_type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 connector_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 connector_version

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 connector_category

  data_type: 'char'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "connector_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "connector_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "connector_version",
  { data_type => "char", is_nullable => 0, size => 32 },
  "connector_category",
  { data_type => "char", is_nullable => 0, size => 32 },
);
__PACKAGE__->set_primary_key("connector_type_id");

=head1 RELATIONS

=head2 connectors

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Connector>

=cut

__PACKAGE__->has_many(
  "connectors",
  "AdministratorDB::Schema::Result::Connector",
  { "foreign.connector_type_id" => "self.connector_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-02-02 10:20:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/SBTaFEUij01TakUalFY8w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
