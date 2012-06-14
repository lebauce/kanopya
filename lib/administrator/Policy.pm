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

package Policy;
use base 'BaseDB';

use strict;
use warnings;

use ParamPreset;
use Entity::ServiceProvider::Inside::Cluster;

use Hash::Merge;

use Data::Dumper;
use Log::Log4perl 'get_logger';

my $log = get_logger('administrator');

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
        'getFlattenedHash' => {
            'description' => 'Return a single level hash with all attributes and values of the policy',
            'perm_holder' => 'entity',
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
        $self = Policy->get(id => $policy_id);

        # Set the policy atrributtes
        for my $name (keys %$attrs) {
            $self->setAttr(name => $name, value => $attrs->{$name});
        }
        $self->save();

        # Remove the old policy configuration parttern.
        my $presets = ParamPreset->get(id => $self->getAttr(name => 'param_preset_id'));

        # Build the policy pattern from
        my $pattern = $class->buildPatternFromHash(policy_type => $attrs->{policy_type}, hash => \%args);
        #my $preset  = ParamPreset->new(name => $attrs->{policy_type}, params => $pattern);
        $presets->update(params => $pattern, override => 1);
        #$self->setAttr(name => 'param_preset_id', value => $preset->getAttr(name => 'param_preset_id'));
    }
    # Else this a policy creation
    else {
        $class->checkAttrs(attrs => $attrs);

        # Build the policy pattern from
        my $pattern = $class->buildPatternFromHash(policy_type => $attrs->{policy_type}, hash => \%args);
        my $preset  = ParamPreset->new(name => $attrs->{policy_type}, params => $pattern);
        $attrs->{param_preset_id} = $preset->getAttr(name => 'param_preset_id');

        $self = $class->SUPER::new(%$attrs);
    }
    return $self;
}

sub buildPatternFromHash {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'policy_type', 'hash' ]);

    my %pattern;
    my $merge = Hash::Merge->new('RIGHT_PRECEDENT');

    # Build the complette list of cluster attributes.
    my $cluster_attrs;
    my $attributes_def = Entity::ServiceProvider::Inside::Cluster->getAttrDefs();
    foreach my $module (keys %$attributes_def) {
        $cluster_attrs = $merge->merge($cluster_attrs, $attributes_def->{$module});
    }

    # Transform the policy form hash to a cluster configuration pattern
    for my $name (keys %{$args{hash}}) {
        # Handle defined values only
        if (defined $args{hash}->{$name} and $args{hash}->{$name}) {
            # Handle managers
            if ($name =~ m/_manager_id/) {
                my $manager_type = $name;
                $manager_type =~ s/_id$//g;

                # Set the manager infos
                $pattern{managers}->{$manager_type} = {
                    manager_id   => $args{hash}->{$name},
                    manager_type => $manager_type
                };

                # Set the manager params if required
                my $manager = Entity->get(id => $args{hash}->{$name});
                my @params = map { $_->{name} } @{ $manager->getPolicyParams(policy_type => $args{policy_type}) };
                for my $param (@params) {
                    if (defined $args{hash}->{$param} and $args{hash}->{$param}) {
                        $pattern{managers}->{$manager_type}->{manager_params}->{$param} = $args{hash}->{$param};
                    }
                }
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
    my $pattern = ParamPreset->get(id => $self->getAttr(name => 'param_preset_id'))->load();

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
        else {
            $flat_hash{$name} = $pattern->{$name};
        }
    }

    $log->debug("Returning flattened policy hash:\n" . Dumper(\%flat_hash));
    return \%flat_hash;
}

sub getParamPreset {
    my $self = shift;
    my %args = @_;

    return ParamPreset->get(id => $self->getAttr(name => 'param_preset_id'));
}

1;
