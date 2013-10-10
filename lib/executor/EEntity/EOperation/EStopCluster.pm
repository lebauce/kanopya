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
    $self->SUPER::check();

    General::checkParams(args => $self->{context}, required => [ "cluster" ]);
}


=pod
=begin classdoc

Check if the cluster is stable.

=end classdoc
=cut

sub prepare {
    my ($self, %args) = @_;
    $self->SUPER::prepare(%args);

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
    $self->SUPER::execute();

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
    NODE:
    foreach my $node (reverse $self->{context}->{cluster}->nodesByWeight()) {
        # We stop nodes with state 'up' only
        # TODO: manage other node states
        my ($state, $timestamp) = $node->host->getState();
        if ($state ne 'up') { next NODE; }

        $self->{context}->{cluster}->removeNode(node_id => $node->id);
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
    $self->SUPER::finish();

    $self->{context}->{cluster}->setState(state => 'stopping');
}

1;
