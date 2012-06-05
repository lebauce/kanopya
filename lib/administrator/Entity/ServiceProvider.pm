# Entity::ServiceProvider.pm  

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

Entity::ServiceProvider

=head1 SYNOPSIS

=head1 DESCRIPTION

blablabla

=cut

package Entity::ServiceProvider;
use base "Entity";

use Kanopya::Exceptions;
use General;
use Entity::Component;
use Entity::Connector;
use Entity::Interface;
use Administrator;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

sub getManager {
	throw Kanopya::Exception::NotImplemented();
}

sub getState {
    throw Kanopya::Exception::NotImplemented();
}

sub findManager {
    my $key;
    my ($class, %args) = @_;
    my @managers = ();

    $key = defined $args{id} ? { component_id => $args{id} } : {};
    $key->{service_provider_id} = $args{service_provider_id} if defined $args{service_provider_id};
    foreach my $component (Entity::Component->search(hash => $key)) {
        my $obj = $component->getComponentAttr();
        if ($obj->{component_category} eq $args{category}) {
            push @managers, {
                "category"            => $obj->{component_category},
                "name"                => $obj->{component_name},
                "id"                  => $component->getAttr(name => "component_id"),
                "service_provider_id" => $component->getAttr(name => "service_provider_id"),
                "host_type"           => $component->can("getHostType") ? $component->getHostType() : "",
            }
        }
    }

    $key = defined $args{id} ? { connector_id => $args{id} } : {};
    $key->{service_provider_id} = $args{service_provider_id} if defined $args{service_provider_id};
    foreach my $connector (Entity::Connector->search(hash => $key)) {
        my $obj = $connector->getConnectorType();

        if ($obj->{connector_category} eq $args{category}) {
            push @managers, {
                "category"            => $obj->{connector_category},
                "name"                => $obj->{connector_name},
                "id"                  => $connector->getAttr(name => "connector_id"),
                "service_provider_id" => $connector->getAttr(name => "service_provider_id"),
                "host_type"           => $connector->can("getHostType") ? $connector->getHostType() : "",
            }
        }
    }

    return @managers;
}

=head2 addNetworkInterface

    Desc: add a network interface on this service provider

=cut

sub addNetworkInterface {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'interface_role' ]);

    my $interface = Entity::Interface->new(
                        interface_role_id   => $args{interface_role}->getAttr(name => 'entity_id'),
                        service_provider_id => $self->getAttr(name => 'entity_id')
                    );

    # Associate to networks if defined
    if (defined $args{networks}) {
        for my $network ($args{networks}) {
            $interface->associateNetwork(network => $network);
        }
    }
    return $interface;
}

=head2 getNetworkInterfaces 

    Desc : return a list of NetworkInterface

=cut

sub getNetworkInterfaces {
    my ($self) = @_;

    # TODO: use the new BaseDb feature,
    # my @interfaces = $self->getRelated(name => 'interfaces');
    my @interfaces = Entity::Interface->search(
                         hash => { service_provider_id => $self->getAttr(name => 'entity_id') }
                     );

    return wantarray ? @interfaces : \@interfaces;
}

=head2 removeNetworkInterface

    Desc: remove a network interface 

=cut

sub removeNetworkInterface {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['interface_id']);

    Entity::Interface->get(id => $args{interface_id})->delete();
}

1;
