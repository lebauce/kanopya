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

package Entity::Policy;
use base 'Entity';

use strict;
use warnings;

use ParamPreset;
use Entity::ServiceProvider::Inside::Cluster;

use Data::Dumper;
use Log::Log4perl 'get_logger';

use POSIX qw[strftime];

my $log = get_logger("");

use constant ATTR_DEF => {
    policy_name => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    policy_desc => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    policy_type => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    param_preset_id => {
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_extended  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        # TODO(methods): Remove this method from the api once the policy ui has been reviewed
        getFlattenedHash => {
            description => 'Return a single level hash with all attributes and values of the policy',
            perm_holder => 'entity',
        },
    };
}

sub new {
    my $class = shift;
    my %args = @_;
    my $self;

    # Firstly pop the policy atrributes
    my $attrs = {
        policy_name => delete $args{policy_name},
        policy_type => delete $args{policy_type},
        policy_desc => delete $args{policy_desc},
    };

    # Pop the policy id if defined
    my $policy_id = delete $args{policy_id};

    # If policy_id defined, this is a policy update.
    if ($policy_id) {
        $self = Entity::Policy->get(id => $policy_id);

        # Set the policy atrributtes
        for my $name (keys %$attrs) {
            $self->setAttr(name => $name, value => $attrs->{$name});
        }
        $self->save();

        # Build the policy pattern from
        my $pattern = $class->buildPatternFromHash(policy_type => $attrs->{policy_type}, hash => \%args);
        $self->param_preset->update(params => $pattern, override => 1);
    }
    # Else this a policy creation
    else {
        $class->checkAttrs(attrs => $attrs);

        # Build the policy pattern from
        my $pattern = $class->buildPatternFromHash(policy_type => $attrs->{policy_type}, hash => \%args);
        my $preset  = ParamPreset->new(params => $pattern);
        $attrs->{param_preset_id} = $preset->id;

        $self = $class->SUPER::new(%$attrs);
    }
    return $self;
}

sub buildPatternFromHash {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'policy_type', 'hash' ]);

    my %pattern;

    # Build the complette list of cluster attributes.
    my $cluster_attrs = Entity::ServiceProvider::Inside::Cluster->getAttrDefs();

    # Transform the policy form hash to a cluster configuration pattern
    for my $name (keys %{$args{hash}}) {
        # Handle defined values only
        if (defined $args{hash}->{$name} and $args{hash}->{$name} ne '') {
            # Handle managers
            if ($name =~ m/_manager_id/) {
                my $manager_type = $name;
                $manager_type =~ s/_id$//g;

                # Set the manager infos
                $pattern{managers}->{$manager_type}->{manager_id} = $args{hash}->{$name};
                $pattern{managers}->{$manager_type}->{manager_type} = $manager_type;

                # Set the manager params if required
                my $manager = Entity->get(id => $args{hash}->{$name});
                my @params = map { $_->{name} } @{ $manager->getPolicyParams(policy_type => $args{policy_type}) };
                for my $param (@params) {
                    if (defined $args{hash}->{$param} and $args{hash}->{$param}) {
                        $pattern{managers}->{$manager_type}->{manager_params}->{$param} = $args{hash}->{$param};
                    }
                }
            }
            # Handle components
            elsif ($name =~ m/^component_type_/ and $args{policy_type} eq 'system') {
                $pattern{components}->{'component_' . $args{hash}->{$name}}->{component_type} = $args{hash}->{$name};
            }
            # Handle networks interfaces
            elsif ($name =~ m/^interface_netconfs_/ and $args{policy_type} eq 'network') {
                # Create the interface array if not exists
                if ($args{hash}->{$name} and ref($args{hash}->{$name}) ne 'ARRAY') {
                    $args{hash}->{$name} = [ $args{hash}->{$name} ];
                }
                my $interface = {};
                for my $netconf (@{ $args{hash}->{$name} }) {
                    $interface->{interface_netconfs}->{$netconf} = $netconf;
                }

                (my $interface_index = $name) =~ s/^interface_netconfs_//g;
                if ($args{hash}->{'bonds_number_' . $interface_index}) {
                    $interface->{bonds_number} = $args{hash}->{'bonds_number_' . $interface_index};
                }

                my $identifier = join('_', @{ $args{hash}->{$name} }) . '_' . $interface->{bonds_number};
                if (defined $pattern{interfaces}->{'interface_' . $identifier}) {
                    $identifier .= '_' .  $interface_index;
                }
                $pattern{interfaces}->{'interface_' . $identifier} = $interface;
            }
            # Handle billing limit
            elsif ($name =~ m/^limit_start_/ and $args{policy_type} eq 'billing') {
                my $limit_index = $name;
                $limit_index    =~ s/^limit_start_//g;

                if (defined($args{hash}->{'limit_ending_' . $limit_index}) and defined($args{hash}->{'limit_value_' . $limit_index}) and
                    defined($args{hash}->{'limit_type_' . $limit_index})) {
                    my $limit   = {
                        start   => $args{hash}->{'limit_start_' . $limit_index},
                        ending  => $args{hash}->{'limit_ending_' . $limit_index},
                        value   => $args{hash}->{'limit_value_' . $limit_index},
                        type    => $args{hash}->{'limit_type_'  . $limit_index}
                    };
                    if (defined($args{hash}->{'limit_soft_' . $limit_index}) and "$args{hash}->{'limit_soft_' . $limit_index}" eq "1") {
                        $limit->{soft}  = "1";
                    }
                    else {
                        $limit->{soft}  = "0";
                    }
                    if ($args{hash}->{'limit_repeats_' . $limit_index} and $args{hash}->{'limit_repeat_start_time_' . $limit_index} and
                        $args{hash}->{'limit_repeat_end_time_' . $limit_index}) {
                        $limit->{repeats}           = $args{hash}->{'limit_repeats_' . $limit_index};
                        $limit->{repeat_start_time} = $args{hash}->{'limit_repeat_start_time_' . $limit_index};
                        $limit->{repeat_end_time}   = $args{hash}->{'limit_repeat_end_time_' . $limit_index};
                    } else {
                        $limit->{repeats}           = 0;
                        $limit->{repeat_start_time} = 0;
                        $limit->{repeat_end_time}   = 0;
                    }
                    $pattern{billing_limits}->{$limit_index}    = $limit;
                  }
            }
            # Can we handle these params whithout hard code  ?
            elsif ($name =~ /systemimage_size/) {
                $pattern{managers}->{disk_manager}->{manager_params}->{$name} = $args{hash}->{$name};
            }
            # Handle orchestration data (already well formatted metrics and rules)
            elsif ($name eq 'orchestration_service_provider_id') {
                $pattern{orchestration}{service_provider_id} = $args{hash}->{$name};
            }
            # Handle cluster attributtes.
            elsif (exists $cluster_attrs->{$name}) {
                # TODO: checkAttr
                $pattern{$name} = $args{hash}->{$name};
            }
        }
    }

    $log->debug("Returning configuration pattern for a $args{policy_type} policy:\n" . Dumper(\%pattern));
    return \%pattern;
}

sub getFlattenedHash {
    my $self = shift;
    my %args = @_;

    my %flat_hash;
    my $pattern = $self->param_preset->load();

    # Transform the policy configuration pattern to a flat hash
    for my $name (keys %$pattern) {
        # Handle managers
        if ($name eq 'managers') {
            for my $manager_type (keys %{$pattern->{$name}}) {
                # Set the manager id
                $flat_hash{$manager_type . '_id'} = $pattern->{$name}->{$manager_type}->{manager_id};

                # Set the manager parameters
                for my $manager_param (keys %{$pattern->{$name}->{$manager_type}->{manager_params}}) {
                    $flat_hash{$manager_param} = $pattern->{$name}->{$manager_type}->{manager_params}->{$manager_param};
                }
            }
        }
        # Handle components
        elsif ($name eq 'components') {
            for my $component (values %{ $pattern->{$name} }) {
                if (not defined $flat_hash{'component_type'}) {
                    $flat_hash{'component_type'} = [];
                }
                push @{ $flat_hash{'component_type'} }, $component->{component_type};
            }
        }
        # Handle network interfaces
        elsif ($name eq 'interfaces') {
            for my $interface (values %{ $pattern->{$name} }) {
                if (not defined $flat_hash{'network_interface'}) {
                    $flat_hash{'network_interface'} = [];
                }

                if (defined $interface->{interface_netconfs} and ref($interface->{interface_netconfs}) eq 'HASH') {
                    my @netconfs = values %{ $interface->{interface_netconfs} };
                    $interface->{interface_netconfs} = \@netconfs;
                }
                push @{ $flat_hash{'network_interface'} }, $interface;
            }
        }
        elsif ($name eq 'billing_limits') {
            for my $billinglimit (values %{ $pattern->{$name} }) {
                my $blimit  = {};
                if (not defined $flat_hash{'billing_limits'}) {
                    $flat_hash{'billing_limits'}    = [];
                }

                for my $k (keys %{ $billinglimit }) {
                    if ("$billinglimit->{$k}" ne "0") {
                        # Must transform times from timestamp to GMT
                        if ($k eq "start" or $k eq "ending"
                            or $k eq "repeat_start_time" or $k eq "repeat_end_time") {
                            my $strftimeformat;
                            if ($k eq "start" or $k eq "ending") {
                                $strftimeformat     = "%d/%m/%Y %H:%M";
                            } else {
                                $strftimeformat     = "%H:%M";
                            }
                            $billinglimit->{$k} = strftime $strftimeformat, localtime($billinglimit->{$k} / 1000);
                        }
                        $blimit->{'limit_' . $k}    = $billinglimit->{$k};
                    }
                }
                push @{ $flat_hash{'billing_limits'} }, $blimit;
            }
        }
        else {
            $flat_hash{$name} = $pattern->{$name};
        }
    }

    $log->debug("Returning flattened policy hash:\n" . Dumper(\%flat_hash));
    return \%flat_hash;
}

1;
