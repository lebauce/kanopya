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

package Entity::Host::VirtualMachine;
use base "Entity::Host";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    hypervisor_id => {
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    vnc_port => {
        pattern      => '^\d+$',
        is_mandatory => 0,
        is_extended  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {};
}

sub scale {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'scalein_value', 'scalein_type' ]);

    return $self->getHostManager->scaleHost(
               host_id       => $self->id,
               scalein_value => $args{scalein_value},
               scalein_type  => $args{scalein_type}
           );
}

sub migrate {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'hypervisor' ]);

    return $self->getHostManager->migrate(
               host_id       => $self->id,
               hypervisor_id => $args{hypervisor}->id,
           );
}

sub getVmInfo {
    my ($self, %args) = @_;
    return {
        hypervisor_id  => $self->hypervisor_id,
    };
}

1;
