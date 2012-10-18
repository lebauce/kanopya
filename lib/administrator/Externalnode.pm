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

package Externalnode;
use base 'BaseDB';

use strict;
use warnings;

# circular reference here
use Entity::ServiceProvider;

use Data::Dumper;
use Log::Log4perl 'get_logger';

my $log = get_logger("");

use constant ATTR_DEF => {
    externalnode_hostname => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    service_provider_id => {
        pattern      => '^\d+$',
        is_mandatory => 1,
        is_extended  => 0
    },
    externalnode_state => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    externalnode_prev_state => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
};


sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        'getMonitoringData'   => {
            'description'   => 'getMonitoringData',
            'perm_holder'   => 'entity'
        },
        'enable'   => {
            'description'   => 'Enable node',
            'perm_holder'   => 'entity'
        },
        'disable'   => {
            'description'   => 'Disable node',
            'perm_holder'   => 'entity'
        },
    };
}

=head2 getMonitoringData

    Desc: call linked collector manager to retrieve indicators values for this node
    Args:
        (required) \@indicator_ids
        $time_span OR $start, $end
        Options : same as CollectorManager::RetrieveData()

    return \%data;

=cut

sub getMonitoringData {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['indicator_ids']);
    my $manager = $self->service_provider->getManager( manager_type => 'collector_manager' );

    # Construst indicators params as expected by CollectorManager
    my %indicators;
    for my $indic_id (@{$args{indicator_ids}}) {
        $indicators{$indic_id} = Indicator->get(id => $indic_id);
    }
    delete $args{indicator_ids};

    my $data = $manager->retrieveData(
        nodelist    => [$self->externalnode_hostname],
        indicators  => \%indicators,
        %args
    );

    return $data->{$self->externalnode_hostname} || {};
}

sub disable {
    my $self = shift;

    my @verified_noderules = $self->verified_noderules;
    while(@verified_noderules) {
        (pop @verified_noderules)->delete();
    }

    $self->setAttr(name => 'externalnode_state', value => 'disabled');
    $self->save();
}

sub enable {
    my $self = shift;

    $self->setAttr(name => 'externalnode_state', value => 'enabled');
    $self->save();
}

1;
