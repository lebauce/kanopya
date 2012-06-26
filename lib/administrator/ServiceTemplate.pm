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

package ServiceTemplate;
use base 'BaseDB';

use strict;
use warnings;

use Policy;

use Data::Dumper;
use Log::Log4perl 'get_logger';

my $log = get_logger('administrator');

use constant ATTR_DEF => {
    service_name => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    service_desc => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    hosting_policy_id => {
        pattern      => '^\d+$',
        is_mandatory => 1,
        is_extended  => 0
    },
    storage_policy_id => {
        pattern      => '^\d+$',
        is_mandatory => 0,
        is_extended  => 0
    },
    network_policy_id => {
        pattern      => '^\d+$',
        is_mandatory => 0,
        is_extended  => 0
    },
    scalability_policy_id => {
        pattern      => '^\d+$',
        is_mandatory => 0,
        is_extended  => 0
    },
    system_policy_id => {
        pattern      => '^\d+$',
        is_mandatory => 0,
        is_extended  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

our $POLICY_TYPES = ['hosting', 'storage', 'network', 'scalability', 'system'];


sub new {
    my $class = shift;
    my %args = @_;
    my $self;

    # Firstly pop the service template atrributes
    my $attrs = {
        service_name => delete $args{service_name},
        service_desc => delete $args{service_desc},
    };

    for my $policy_type (@$POLICY_TYPES) {
        if (not $args{$policy_type . '_policy_id'}) {
            my $policy_args = {};
            my $pattern = $policy_type . '_';

            for my $arg (grep /$pattern/, keys %args) {
                $arg =~ s/^$pattern//g;
                if ($arg eq 'policy_name') {
                    $args{$pattern . $arg} .= ' (for service "' . $attrs->{service_name} .  '")';
                }
                $policy_args->{$arg} = $args{$pattern . $arg};
            }
            $policy_args->{policy_type} = $policy_type;

            my $policy = Policy->new(%$policy_args);
            $args{$policy_type . '_policy_id'} = $policy->getAttr(name => 'policy_id');
        }
        $attrs->{$policy_type . '_policy_id'} = $args{$policy_type . '_policy_id'};
    }

    return $class->SUPER::new(%$attrs);
}

sub getPolicies () {
    my $self = shift;
    my %args = @_;

    my $policies = [];

    # The service template known the type of policies
    for my $policy_type (@$POLICY_TYPES) {
        push @$policies, Policy->get(id => $self->getAttr(name => $policy_type . '_policy_id'));
    }
    return $policies;
}

1;
