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
use Administrator;

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

sub getDefaultManager {
    throw Kanopya::Exception::NotImplemented();
}

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
    General::checkParams(args => \%args, required => ['interface_role_id']);
    my $adm = Administrator->new;
    $adm->{db}->resultset('Interface')->create(
        {
            interface_role_id   => $args{interface_role_id},
            service_provider_id => $self->getAttr(name => 'service_provider_id')
        }
    );
}

=head2 getNetworkInterfaces 

    Desc : return a list of NetworkInterface

=cut

sub getNetworkInterfaces {
    my ($self) = @_;
    my $adm = Administrator->new;
    my @rows = $adm->{db}->resultset('Interface')->search(
        { service_provider_id => $self->getAttr(name => 'service_provider_id') },
        { '+columns' => { 'interface_role_name' => 'interface_role.interface_role_name' },
         join => ['interface_role']
        }
    );
    my @interfaces = ();
    foreach my $row (@rows) {
        push @interfaces, { $row->get_columns };
    }
    
    return wantarray ? @interfaces : \@interfaces;    
}

=head2 removeNetworkInterface

    Desc: remove a network interface 

=cut

sub removeNetworkInterface {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['interface_id']);
    my $adm = Administrator->new;
    $adm->{db}->resultset('Interface')->find($args{interface_id})->delete;
}

1;
