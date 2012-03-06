# Entity::ServiceProvider::Outside.pm  

#    Copyright © 2011 Hedera Technology SAS
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 16 july 2010

=head1 NAME

Entity::ServiceProvider::Outside

=head1 SYNOPSIS

=head1 DESCRIPTION

blablabla

=cut

package Entity::ServiceProvider::Outside;
use base "Entity::ServiceProvider";

use Entity::Connector;

use Log::Log4perl "get_logger";

my $log = get_logger("administrator");

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }


sub getManager {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['id']);

    return Entity::Connector->get(id => $args{id});
}

=head2 addConnector

link an existing connector with the outside service provider

=cut

sub addConnector {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['connector']);

    my $connector = $args{connector};
    $connector->setAttr(name => 'outside_id', value => $self->getAttr(name => 'outside_id'));
    $connector->save();

    return $connector->{_dbix}->id;
}

=head2 addConnectorFromType

Create and link a connector from type to the outside service provider

=cut

sub addConnectorFromType {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['connector_type_id']);
    my $type_id = $args{connector_type_id};
    my $adm = Administrator->new();
    my $row = $adm->{db}->resultset('ConnectorType')->find($type_id);
    my $conn_name = $row->get_column('connector_name');
    my $conn_class = 'Entity::Connector::'.$conn_name;
    my $location = General::getLocFromClass(entityclass => $conn_class);
    eval {require $location };
    my $connector = $conn_class->new();

    $self->addConnector( connector => $connector );

    return $connector->{_dbix}->id;
}

=head2 removeConnector

remove a connector from id

=cut

sub removeConnector {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['connector_id']);

    my $connector = Entity::Connector->get(id => $args{connector_id});
    $connector->delete;

}

=head2 getConnector

Get the concrete linked connector of category <category>

=cut

# Same behaviour than Cluster::getComponent
# TODO factorize!
sub getConnector {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['category']);
    
    # Retrieve associated connector of category
    my $connectors_rs = $self->{_dbix}->parent->search_related(
        "connectors",
        { 'connector_type.connector_category' => $args{category} },
        { join => ["connector_type"] }
    );
    
    my $connector_row = $connectors_rs->next;
    if (not defined $connector_row) {
        throw Kanopya::Exception::Internal(error => "No linked connector of category '$args{category}'");
    }
    if ($connectors_rs->count > 1) {
        $log->info("More than one connector of category '$args{category}'");
    }
    my $connector_name = $connector_row->connector_type->connector_name;
    my $connector_id   = $connector_row->id;
    $log->info("Take connector '$connector_name', id $connector_id");

    # Get concrete connector
    my $class= "Entity::Connector::" . $connector_name;
    my $loc = General::getLocFromClass(entityclass=>$class);
    eval { require $loc; };
    return "$class"->get(id =>$connector_id);
}

sub getConnectors {
    my $self = shift;
    my %args = @_;
    
    return Entity::Connector->search(hash => {outside_id => $self->getAttr(name => 'outside_id')});
}

1;
