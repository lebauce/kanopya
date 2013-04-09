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

package EEntity::EOperation::EStopCluster;
use base "EEntity::EOperation";

use strict;
use warnings;
use Log::Log4perl "get_logger";
use Entity::ServiceProvider::Cluster;
my $log = get_logger("");
my $errmsg;

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    General::checkParams(args => $self->{context}, required => [ "cluster" ]);
}

sub execute {
    my $self = shift;
    $self->SUPER::execute();

    my @nodes = $self->{context}->{cluster}->nodesByWeight();
    if (not scalar(@nodes)) {
        $self->{context}->{cluster}->setState(state  => 'stopping');
        $errmsg = "This cluster <" . $self->{context}->{cluster}->id . "> seems to have no node.";
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    # Remove node from the less important to the most important
    foreach my $node (reverse @nodes) {
        # We stop nodes with state 'up' only
        # TODO: manage other node states
        my ($state, $timestamp) = $node->host->getState();
        if ($state ne 'up') { next; }

        $self->{context}->{cluster}->removeNode(node_id => $node->id);
    }

    $self->{context}->{cluster}->setState(state => 'stopping');
    $self->{context}->{cluster}->save();
}

1;
