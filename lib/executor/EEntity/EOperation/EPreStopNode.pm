#    Copyright © 2011 Hedera Technology SAS
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package EEntity::EOperation::EPreStopNode;
use base "EEntity::EOperation";

use strict;
use warnings;

use Kanopya::Exceptions;
use Entity::Host;
use EEntity;

use String::Random;
use Date::Simple (':all');

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;


sub prerequisites {
    my ($self, %args) = @_;

    General::checkParams(args => $self->{context}, required => []);

    my $delay = 10;

    # Choose a random non master node
    if ((not defined $self->{context}->{host}) && (defined $self->{context}->{cluster})) {
        $log->info('No node selected, select a random node');

        # Search the less important non master node
        my @nodes = $self->{context}->{cluster}->nodesByWeight(master_node => 0);
        if (not scalar (@nodes)) {
            throw Kanopya::Exception(error => 'Cannot remove a node from cluster <'.($self->{context}->{cluster}->id).'>, only master nodes left');
        }
        my $node = pop @nodes;

        $log->info('Node <' . $node->id . '> selected to be removed among <' . (scalar @nodes) . '> nodes');
        $self->{context}->{host} = EEntity->new(data => $node->host);
    }

    if ($self->{context}->{host}->checkStoppable == 0) {
        $log->info('Need to flush the hypervisor before stopping it');

        my $operation_to_enqueue = {
            type     => 'FlushHypervisor',
            priority => 1,
            params   => { context => { host => $self->{context}->{host} } }
        };

        $self->workflow->enqueueBefore(operation => $operation_to_enqueue);
        $log->info('Enqueue "add hypervisor" operations before starting a new virtual machine');
        return -1;
    }

    if (not defined $self->{context}->{cluster}) {
         my $cluster = Entity->get(id => $self->{context}->{host}->node->service_provider_id);
         $self->{context}->{cluster} = $cluster;
    }
    return 0;
}

sub execute {
    my $self = shift;
    $self->SUPER::execute();

    my @components = $self->{context}->{cluster}->getComponents(category => "all");
    $log->info('Inform cluster components about node removal');

    foreach my $component (@components) {
        EEntity->new(data => $component)->preStopNode(
            host      => $self->{context}->{host},
            cluster   => $self->{context}->{cluster},
            erollback => $self->{erollback}
        );
    }
    $self->{context}->{host}->setNodeState(state => "pregoingout");
}

1;
