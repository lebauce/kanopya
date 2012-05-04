# Copyright © 2011 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package Entity::Interface;
use base "Entity";

use Kanopya::Exceptions;

use Entity::Iface;
use Entity::Poolip;
use Entity::Network;
use Entity::InterfaceRole;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
    interface_role_id => {
        pattern      => '^\d+$',
        is_mandatory => 1,
    },
    service_provider_id => {
        pattern      => '^\d+$',
        is_mandatory => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub getRole {
    my $self = shift;
    my %args = @_;

    return Entity::InterfaceRole->get(id => $self->getAttr(name => 'interface_role_id' ));
}

sub getNetworks {
    my $self = shift;
    my %args = @_;
    my @networks = ();

    my $interface_networks = $self->{_dbix}->interface_networks;
    while (my $interface_network = $interface_networks->next) {
        push @networks, Entity::Network->get(id => $interface_network->get_column('network_id'));
    }

    return @networks;
}

sub associateNetwork {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'network' ]);

    $self->{_dbix}->interface_networks->create({
        network_id => $args{network}->getAttr(name => 'entity_id')
    });
}

sub assignIpToIface {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'iface' ]);

    my $assigned = 0;
    if ($self->getRole->getAttr(name => 'interface_role_name') ne 'vms') {
        # Try to use poolips of the first associated network.
        my $interface_networks = $self->{_dbix}->interface_networks;
        while (my $interface_network = $interface_networks->next) {
            # Try all asscoiated poolips
            my $network_poolips = $interface_network->network->network_poolips;
            while (my $net_poolip = $network_poolips->next){
                my $poolip = Entity::Poolip->get(id => $net_poolip->poolip->get_column('poolip_id'));

                # Try to pop an ip from the current pool
                my $ip;
                eval { $ip = $poolip->popIp(); };
                if ($@) {
                    $log->info("Cannot pop IP from pool <" . $poolip->getAttr(name => 'poolip_name') . ">\n$@");
                    next;
                }
                $ip->setAttr(name  => 'iface_id', value => $args{iface}->getAttr(name => 'entity_id'));
                $ip->save();

                $assigned = 1;
                last;
            }
        }
        # No free ip found
        if (not $assigned) {
            throw Kanopya::Exception::Internal::NotFound(
                      error => "Unable to assign ip to iface <" .
                               $args{iface}->getAttr(name => 'iface_name') . ">"
                  );
        }
    }
}

sub getAssociatedIface {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    return Entity::Iface->find(hash => { interface_id => $self->getAttr(name => 'entity_id'),
                                         host_id      => $args{host}->getAttr(name => 'entity_id') });
}

1;
