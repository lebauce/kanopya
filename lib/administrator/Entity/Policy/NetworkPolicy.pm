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
    interfaces => {
        label        => 'Interfaces',
        type         => 'relation',
        relation     => 'single_multi',
        is_editable  => 1,
        is_mandatory => 1,
        attributes   => {
            attributes => {
                policy_id => {
                    type     => 'relation',
                    relation => 'single',
                },
                netconfs => {
                    label       => 'Network configurations',
                    type        => 'relation',
                    relation    => 'multi',
                    link_to     => 'netconf',
                    pattern     => '^\d*$',
                    is_editable => 1,
                },
                bonds_number => {
                    label       => 'Bonding slave count',
                    type        => 'integer',
                    pattern     => '^\d*$',
                    is_editable => 1,
                },
                interface_name => {
                    label        => 'Name',
                    type         => 'string',
                    pattern      => '^.*$',
                    is_editable  => 1,
                    is_mandatory => 1,
                },
            },
        },
    }
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
    push @{ $args{attributes}->{displayed} },
        { interfaces => [ 'interface_name', 'netconfs', 'bonds_number' ] };

    # Add the network interfaces to the relations definition
    $args{attributes}->{relations}->{interfaces} = {
        attrs    => { accessor => 'multi' },
        cond     => { 'foreign.policy_id' => 'self.policy_id' },
        resource => 'interface'
    };

    # Build the default gateway network list
    my @networks;
    for my $network (Entity::Network->search(hash => {})) {
        push @networks, $network->toJSON();
    }
    my @netconfs;
    for my $netconf (Entity::Netconf->search(hash => {})) {
        push @netconfs, $netconf->toJSON();
    }

    $args{attributes}->{attributes}->{default_gateway_id}->{options} = \@networks;
    $args{attributes}->{attributes}->{interfaces}->{attributes}->{attributes}->{netconfs}->{options}
        = \@netconfs;

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

    my $pattern = $self->SUPER::getPatternFromParams(params => $args{params});

    if (ref($args{params}->{interfaces}) eq 'ARRAY') {
        my $index = 0;
        my $interfaces = {};
        for my $interface (@{ delete $args{params}->{interfaces} }) {
            if (ref($interface->{netconfs}) ne 'ARRAY') {
                $interface->{netconfs} = [ $interface->{netconfs} ];
            }
            # Transform the netconfs list into a params for merging purpose
            my %netconfs = map { $_ => $_ } @{ $interface->{netconfs} };
            $interface->{netconfs} = \%netconfs;

            $interfaces->{'interface_' . $interface->{interface_name}} = $interface;
            $index++;
        }
        $pattern->{interfaces} = $interfaces;
    }
    return $pattern;
}

1;
