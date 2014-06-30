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

package  Entity::Component::Vmm::NovaCompute;
use base "Entity::Component::Vmm";

use strict;
use warnings;

use Hash::Merge qw(merge);
use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    iaas_id => {
        label        => 'Openstack controller',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_editable  => 1,
        specialized  => 'NovaController'
    },
    libvirt_type => {
        type         => 'enum',
        label        => 'libvirt type',
        pattern      => '^(kvm|qemu)$',
        options      => { 'kvm' => 'KVM',
                          'qemu' => 'QEMU' },
        is_mandatory => 0,
        is_editable  => 1,
        default      => 'kvm',
    },
};

sub getAttrDef { return ATTR_DEF; }

sub nova_controller {
    return shift->iaas;
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'cluster', 'host' ]);

    # The support of network is very limited
    # We create only one bridge for all the networks with no VLAN
    # and a bridge for all the networks with VLAN

    my $bridge_vlan;
    my $bridge_flat;

    IFACE:
    for my $iface ($args{host}->getIfaces()) {
        next IFACE if $iface->hasRole(role => 'admin');

        for my $netconf ($iface->netconfs) {
            if (scalar $netconf->vlans) {
                $bridge_vlan = $iface->iface_name if not $bridge_vlan;
                next IFACE;
            }
        }

        $bridge_flat = $iface->iface_name if not $bridge_flat;
    }

    my @uplinks;

    if ($bridge_flat) {
        push @uplinks, "br-flat:" . $bridge_flat;
    }

    if ($bridge_vlan) {
        push @uplinks, "br-vlan:" . $bridge_vlan;
    }

    my @optionals = ($self->nova_controller->amqp, $self->nova_controller->keystone);
    my @neutrons = $self->nova_controller->neutrons;
    my @glances = $self->nova_controller->glances;
    push @optionals, $neutrons[0] if @neutrons;
    push @optionals, $glances[0] if @glances;

    return merge($self->SUPER::getPuppetDefinition(%args), {
        novacompute => {
            classes => {
                "kanopya::openstack::nova::compute" => {
                    bridge_uplinks => \@uplinks,
                    email => $self->nova_controller->getMasterNode->owner->user_email,
                    libvirt_type => $self->libvirt_type,
                    rabbit_user => "nova-" . $self->nova_controller->id,
                    rabbit_virtualhost => 'openstack-' . $self->nova_controller->id
                }
            },
            optionals => \@optionals
        }
    } );
}


=pod
=begin classdoc

NovaCompute depend on the keystone, amqp and glances of the nova controller.

=end classdoc
=cut

sub getDependentComponents {
    my ($self, %args) = @_;

    my @dependent = ($self->nova_controller->glances,
                     $self->nova_controller->keystone,
                     $self->nova_controller->amqp);

    return \@dependent;
}


sub checkConfiguration {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { 'ignore' => [] });

    $self->checkAttribute(attribute => "iaas");

    my $component = $self->iaas;
    if (scalar(grep { $component->id == $_->id } @{ $args{ignore} }) == 0) {
        $self->checkDependency(component => $component);
    }
    else {
        $log->debug("Ignore the check of the dependent component $component");
    }
}

1;
