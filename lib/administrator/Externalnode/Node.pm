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

package Externalnode::Node;
use base 'Externalnode';

use strict;
use warnings;

use Entity;
use Data::Dumper;
use Log::Log4perl 'get_logger';
my $log = get_logger("");

use constant ATTR_DEF => {
    host_id => {
        pattern      => '^\d+$',
        is_mandatory => 1,
        is_extended  => 0
    },
    inside_id => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0,
    },
    master_node => {
        pattern      => '^\d+$',
        is_mandatory => 0,
        is_extended  => 0
    },
    node_state => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    node_prev_state => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    node_number => {
        pattern      => '^\d+$',
        is_mandatory => 1,
        is_extended  => 0
    },
    systemimage_id => {
        pattern      => '^\d+$',
        is_mandatory => 0,
        is_extended  => 0
    },
};


sub getAttrDef { return ATTR_DEF; }

sub new {
    my ($class, %args) = @_;

    my $host = Entity->get(id => $args{host_id});
    my $self = $class->SUPER::new(
                   service_provider_id   => $args{inside_id},
                   externalnode_hostname => $host->host_hostname,
                   externalnode_state    => "enabled",
                   %args,
               );

    return $self;
}

sub getServiceProvider() {
    my $self = shift;

    return Entity->get(id => $self->getAttr(name => 'service_provider_id'));
}

sub remove() {
    my $self = shift;

    my $serviceProvider = $self->getServiceProvider();
    $serviceProvider->removeNode('host_id' => $self->getAttr(name => 'host_id'));
}

sub getDelegatee {
    my $self = shift;
    my $class = ref $self;

    if (not $class) {
        return "Entity::ServiceProvider";
    }
    else {
        return $self->service_provider;
    }
}

1;
