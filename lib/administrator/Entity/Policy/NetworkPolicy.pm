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

package Entity::Policy::NetworkPolicy;
use base 'Entity::Policy';

use strict;
use warnings;

use Data::Dumper;
use Log::Log4perl 'get_logger';

use Clone qw(clone);

my $log = get_logger("");

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

use constant POLICY_ATTR_DEF => {
    cluster_domainname => {
        label   => 'Domain name',
        type    => 'string',
        pattern => '^[a-z0-9-]+(\\.[a-z0-9-]+)+$',
    },
    cluster_nameserver1 => {
        label   => 'Name server 1',
        type    => 'string',
        pattern => '^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$'
    },
    cluster_nameserver2 => {
        label   => 'Name server 2',
        type    => 'string',
        pattern => '^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$'
    },
    default_gateway_id => {
        label    => 'Default gateway network',
        type     => 'relation',
        relation => 'single',
        pattern  => '^\d*$',
    },
    interfaces => {
        label       => 'Interfaces',
        type        => 'relation',
        relation    => 'single_multi',
        is_editable => 1,
        attributes  => {
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
            },
        },
    }
};

sub getPolicyAttrDef { return POLICY_ATTR_DEF; }


my $merge = Hash::Merge->new('RIGHT_PRECEDENT');

sub getPolicyDef {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         optional => { 'set_mandatory'       => 0,
                                       'set_editable'        => 1,
                                       'set_params_editable' => 0 });

    %args = %{ $self->mergeValues(values => \%args) };

    # Build the default gateway network list
    my @networks;
    for my $network (Entity::Network->search(hash => {})) {
        push @networks, $network->toJSON();
    }
    my @netconfs;
    for my $netconf (Entity::Netconf->search(hash => {})) {
        push @netconfs, $netconf->toJSON();
    }

    my $policy_attrdef = clone($class->getPolicyAttrDef);
    $policy_attrdef->{default_gateway_id}->{options} = \@networks;
    $policy_attrdef->{interfaces}->{attributes}->{attributes}->{netconfs}->{options} = \@netconfs;

    my $attributes = {
        displayed  => [ 'cluster_domainname', 'cluster_nameserver1', 'cluster_nameserver2', 'default_gateway_id' ],
        attributes => $policy_attrdef,
        relations => {
            interfaces => {
                attrs    => { accessor => 'multi' },
                cond     => { 'foreign.policy_id' => 'self.policy_id' },
                resource => 'interface'
            },
        },
    };

    push @{ $attributes->{displayed} }, {
        'interfaces' => [ 'netconfs', 'bonds_number' ]
    };

    # Complete the attributes with common ones
    $attributes = $merge->merge($self->SUPER::getPolicyDef(%args), $attributes);

    $self->setValues(attributes          => $attributes,
                     values              => \%args,
                     set_mandatory       => delete $args{set_mandatory},
                     set_editable        => delete $args{set_editable},
                     set_params_editable => delete $args{set_params_editable});

    return $attributes;
}

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

            my $identifier = join('_', keys %{ $interface->{netconfs} }) . '_' . $interface->{bonds_number};
            if (defined $interfaces->{'interface_' . $identifier}) {
                $identifier .= '_' .  $index;
            }
            $interfaces->{'interface_' . $identifier} = $interface;
            $index++;
        }
        $pattern->{interfaces} = $interfaces;
    }
    return $pattern;
}

1;
