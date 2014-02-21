#    Copyright © 2011 Hedera Technology SAS
#
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

package  Entity::Component::Openstack::Neutron;
use base "Entity::Component";

use strict;
use warnings;

use Hash::Merge qw(merge);
use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    mysql5_id => {
        label        => 'Database server',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_editable  => 1,
    },
    nova_controller_id => {
        label        => 'Openstack controller',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_editable  => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub getNetConf {
    return {
        neutron => {
            port => 9696,
            protocols => ['tcp']
        }
    };
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    my $definition = $self->SUPER::getPuppetDefinition(%args);
    my $name = "neutron-" . $self->id;

    return merge($self->SUPER::getPuppetDefinition(%args), {
        neutron => {
            classes => {
                'kanopya::openstack::neutron::server' => {
                    bridge_flat => 'br-flat',
                    email => $self->service_provider->owner->user_email,
                    database_user => $name,
                    database_name => $name,
                    rabbit_user => $name,
                    rabbit_virtualhost => 'openstack-' . $self->nova_controller->id
                }
            },
            dependencies => [ $self->nova_controller->keystone,
                              $self->nova_controller->amqp,
                              $self->mysql5 ]
        }
    } );
}

sub getHostsEntries {
    my $self = shift;

    my @entries = ($self->nova_controller->keystone->service_provider->getHostEntries(),
                   $self->nova_controller->amqp->service_provider->getHostEntries(),
                   $self->mysql5->service_provider->getHostEntries());

    return \@entries;
}

sub checkConfiguration {
    my $self = shift;

    for my $attr ("mysql5", "nova_controller") {
        $self->checkAttribute(attribute => $attr);
    }

    for my $component ($self->mysql5, $self->nova_controller->keystone, $self->nova_controller->amqp) {
        $self->checkDependency(component => $component);
    }
}

1;
