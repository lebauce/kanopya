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

package Entity::Host::Hypervisor;
use base "Entity::Host";

use strict;
use warnings;

use Entity::Host::VirtualMachine;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        maintenance => {
            description => 'flush the hypervisor and deactivate it',
        }
    }
}

sub getVms {
    my $self = shift;
    my %args = @_;

    my @vms = Entity::Host::VirtualMachine->search(hash => { hypervisor_id => $self->id });

    return wantarray ? @vms : \@vms;
}

sub checkStoppable {
    my $self = shift;
    my @vms = $self->getVms();

    if (scalar @vms) {
        throw Kanopya::Exception(error => "The hypervisor " . $self->node->node_hostname .
                                          " can't be stopped as it still runs virtual machines");
    }

    return 0;
}

sub getCloudManager {
    throw Kanopya::Exception::NotImplemented();
}

sub maintenance {
    my $self = shift;

    $self->getCloudManager->service_provider->getManager(manager_type => 'ExecutionManager')->run(
        name   => 'HypervisorMaintenance',
        params => {
            context => {
                host => $self,
            }
        }
    );
}

sub resubmitVms {
    my $self = shift;

    $self->getCloudManager->service_provider->getManager(manager_type => 'ExecutionManager')->run(
        name   => 'ResubmitHypervisor',
        params => {
            context => {
                host => $self,
            }
        }
    );
}

1;
