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

package  Entity::Component::Openstack::Quantum;
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
        quantum => {
            port => 9696,
            protocols => ['tcp']
        }
    };
}

sub getPuppetDefinition {
    my ($self, %args) = @_;
    my $definition = $self->SUPER::getPuppetDefinition(%args);

    my $keystone =  $self->nova_controller->keystone->getBalancerAddress(port => 5000) ||
                    $self->nova_controller->keystone->getMasterNode->fqdn;
    
    my $amqp = $self->nova_controller->amqp->getMasterNode->fqdn;
    
    my $sql = $self->mysql5->getBalancerAddress(port => 3306) ||
              $self->mysql5->getMasterNode->fqdn;
    
    my $name = "quantum-" . $self->id;

    my $manifest = $self->instanciatePuppetResource(
        name => 'kanopya::openstack::quantum::server',
        params => {
            bridge_flat => 'br-flat',
            bridge_vlan => 'br-vlan',
            email => $self->service_provider->user->user_email,
            database_user => $name,
            database_name => $name,
            rabbit_user => $name,
            rabbit_virtualhost => 'openstack-' . $self->nova_controller->id
        }
    );

    return merge($self->SUPER::getPuppetDefinition(%args), {
        quantum => {
            manifest     => $manifest,
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
}

1;
