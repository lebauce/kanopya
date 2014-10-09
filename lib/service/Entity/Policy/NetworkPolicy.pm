# Copyright © 2011-2012 Hedera Technology SAS
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

=pod

=begin classdoc

The network policy defines the parameters describing how a service
manage the network interfaces of it's hosts.

@since    2012-Aug-16
@instance hash
@self     $self

=end classdoc

=cut

package Entity::Policy::NetworkPolicy;
use base 'Entity::Policy';

use strict;
use warnings;

use Entity::Netconf;
use Entity::Network;

use Data::Dumper;
use Log::Log4perl 'get_logger';

use Clone qw(clone);

my $log = get_logger("");

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

use constant POLICY_ATTR_DEF => {
    cluster_domainname => {
        label        => 'Domain name',
        type         => 'string',
        pattern      => '^[a-z0-9-]+(\\.[a-z0-9-]+)+$',
        is_mandatory => 1
    },
    cluster_nameserver1 => {
        label        => 'Name server 1',
        type         => 'string',
        pattern      => '^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$',
        is_mandatory => 1
    },
    cluster_nameserver2 => {
        label        => 'Name server 2',
        type         => 'string',
        pattern      => '^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$',
        is_mandatory => 1
    },
    default_gateway_id => {
        label        => 'Default gateway network',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        is_mandatory => 1
    },
    network_manager_id => {
        label        => "Network manager",
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        reload       => 1,
        is_mandatory => 1,
    },
};

sub getPolicyAttrDef { return POLICY_ATTR_DEF; }

my $merge = Hash::Merge->new('RIGHT_PRECEDENT');


=pod
=begin classdoc

Build the dynamic attributes definition depending on attributes
values given in parameters.

@return the dynamic attributes definition.

=end classdoc
=cut

sub getPolicyDef {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         required => [ 'attributes' ],
                         optional => { 'params' => {}, 'trigger' => undef });

    # Add the dynamic attributes to displayed
    push @{ $args{attributes}->{displayed} }, 'cluster_domainname';
    push @{ $args{attributes}->{displayed} }, 'cluster_nameserver1';
    push @{ $args{attributes}->{displayed} }, 'cluster_nameserver2';
    push @{ $args{attributes}->{displayed} }, 'default_gateway_id';
    push @{ $args{attributes}->{displayed} }, 'network_manager_id';

    # Build the default gateway network list
    my @networks;
    for my $network (Entity::Network->search(hash => {})) {
        push @networks, $network->toJSON();
    }
    $args{attributes}->{attributes}->{default_gateway_id}->{options} = \@networks;

    # Build the list of network managers
    my $manager_options = {};
    for my $component (Entity::Component->search(custom => { category => 'NetworkManager' })) {
        $manager_options->{$component->id} = $component->toJSON;
        $manager_options->{$component->id}->{label} = $component->label;
    }
    my @manageroptions = values %{$manager_options};
    $args{attributes}->{attributes}->{network_manager_id}->{options} = \@manageroptions;

    # If network_manager_id defined but do not corresponding to a available value,
    # it is an old value, so delete it.
    if (not $manager_options->{$args{params}->{network_manager_id}}) {
        delete $args{params}->{network_manager_id};
    }
    # If no disk_manager_id defined and and attr is mandatory, use the first one as value
    if (! $args{params}->{network_manager_id} && $args{set_mandatory}) {
        $self->setFirstSelected(name       => 'network_manager_id',
                                attributes => $args{attributes}->{attributes},
                                params     => $args{params});
    }

    if ($args{params}->{network_manager_id}) {
        # Get the network manager params from the selected network manager
        my $networkmanager = Entity->get(id => $args{params}->{network_manager_id});
        my $managerparams = $networkmanager->getNetworkManagerParams(params => $args{params});

        for my $attrname (keys %{ $managerparams }) {
            $args{attributes}->{attributes}->{$attrname} = $managerparams->{$attrname};
            # If no value defined in params, use the first one
            if (! $args{params}->{$attrname} && $args{set_mandatory}) {
                $self->setFirstSelected(name       => $attrname,
                                        attributes => $args{attributes}->{attributes},
                                        params     => $args{params});
            }

            # If the attribute is a manager, set it as reload trigger as
            # it probably hav specific params too
            if ($attrname =~ m/.*_manager_id/) {
                $args{attributes}->{attributes}->{$attrname}->{reload} = 1;
            }

            # HCMNetworkManager specific, should not be in the generic policy code
            if ($attrname eq "interfaces") {
                push @{ $args{attributes}->{displayed} },
                    { interfaces => [ 'interface_name', 'netconfs', 'bonds_number' ] };

                # Add the network interfaces to the relations definition
                $args{attributes}->{relations}->{interfaces} = {
                    attrs    => { accessor => 'multi' },
                    cond     => { 'foreign.policy_id' => 'self.policy_id' },
                    resource => 'interface'
                };
            }
            else {
                # Add the attribute to the displayed list
                push @{ $args{attributes}->{displayed} }, $attrname;
            }
        }
    }
    # Remove possibly defined value of attributes that depends on disk_manager_id.
    # (It is probably a first implementation of the full generic version of
    # manager management in policies...)
    else {
        for my $dependency (@{ $self->getPolicySelectorMap->{network_manager_id} }) {
            delete $args{params}->{$dependency};
        }
    }

    return $args{attributes};
}


=pod
=begin classdoc

Handle network policy specific parameters to build
the policy pattern. Here, handle the list of network interfaces
by transforming the interfaces array to a hash, indexed by unique
keys to allows to merge with another policies.

@return a policy pattern fragment

=end classdoc
=cut

sub getPatternFromParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'params' ]);

    # HCMNetworkManager specific, should not be in the generic policy code
    if (ref($args{params}->{interfaces}) eq 'ARRAY') {
        my $interfaces = {};
        for my $interface (@{ delete $args{params}->{interfaces} }) {
            if (ref($interface->{netconfs}) ne 'ARRAY') {
                $interface->{netconfs} = [ $interface->{netconfs} ];
            }
            # Transform the netconfs list into a params for merging purpose
            my %netconfs = map { $_ => $_ } @{ $interface->{netconfs} };
            $interface->{netconfs} = \%netconfs;

            $interfaces->{'interface_' . $interface->{interface_name}} = $interface;
        }
        $args{params}->{interfaces} = $interfaces;
    }

    # OpenStack specific, should not be in the generic policy code
    if (ref($args{params}->{subnets}) eq 'ARRAY') {
        my %subnets = map { $_ => $_ } @{ delete $args{params}->{subnets} };
        $args{params}->{subnets} = \%subnets;
    }

    return $self->SUPER::getPatternFromParams(params => $args{params});
}

1;
