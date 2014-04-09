#    Copyright © 2011-2013 Hedera Technology SAS
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

=pod
=begin classdoc

Stop the cluster. Run as many StopNode wofkflows as number of remaning nodes.

@since    2012-Aug-20
@instance hash
@self     $self

=end classdoc
=cut

package EEntity::EOperation::EStopCluster;
use base EEntity::EOperation;

use strict;
use warnings;

use Log::Log4perl "get_logger";
my $log = get_logger("");
my $errmsg;


=pod
=begin classdoc

@param cluster the cluster to stop

=end classdoc
=cut

sub check {
    my ($self, %args)  = @_;

    General::checkParams(args => $self->{context}, required => [ "cluster" ]);
}


=pod
=begin classdoc

Check if the cluster is stable.

=end classdoc
=cut

sub prepare {
    my ($self, %args) = @_;

    # Check the cluster state
    my ($state, $timestamp) = $self->{context}->{cluster}->reload->getState;
    if ($state ne 'up') {
        throw Kanopya::Exception::Execution::InvalidState(
                  error => "The cluster <" . $self->{context}->{cluster} .
                           "> has to be <up>, not <$state>"
              );
    }
    $self->{context}->{cluster}->setState(state => 'updating');
}


=pod
=begin classdoc

Fail if the cluster has no nodes.

=end classdoc
=cut

sub execute {
    my ($self, %args)  = @_;

    my @nodes = $self->{context}->{cluster}->nodes;
    if (not scalar(@nodes)) {
        $errmsg = "This cluster <" . $self->{context}->{cluster}->id . "> seems to have no node.";
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}


=pod
=begin classdoc

Run as many StopNode wofkflows as number of remaning nodes.

=end classdoc
=cut

sub postrequisites {
    my ($self, %args)  = @_;

    # Remove node from the less important to the most important
    # Note: nodesByWeight return the node list sorted from the most important to the less important
    #       but as we use enqueueNow, the workflow will be executed in the reserve order than we
    #       enqueued them.
    NODE:
    foreach my $node ($self->{context}->{cluster}->nodesByWeight()) {
        # We stop nodes with state 'up' only
        # TODO: manage other node states
        my ($state, $timestamp) = $node->host->getState();
        if ($state ne 'up') {
            $log->warn("Node " . $node->label . " is not 'up', do not stopping it...");
            next NODE;
        }

        # Stop the node in an embedded workflow
        $self->workflow->enqueueNow(
            workflow => {
                name       => 'StopNode',
                related_id => $self->{context}->{cluster}->id,
                params     => {
                    context => {
                        cluster => $self->{context}->{cluster}->_entity,
                        host    => $node->host,
                    }
                }
            },
            harmless => $self->harmless,
        );
    }

    return 0;
}


=pod
=begin classdoc

Set the cluster as stopping

=end classdoc
=cut

sub finish {
    my ($self, %args)  = @_;

    $self->{context}->{cluster}->setState(state => 'stopping');
}

1;
