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

use Log::Log4perl "get_logger";


my $log = get_logger("administrator");

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

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

1;
