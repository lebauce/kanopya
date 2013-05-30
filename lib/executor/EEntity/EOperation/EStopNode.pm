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

Stop the host corresponding to the node to remove.

@since    2012-Aug-20
@instance hash
@self     $self

=end classdoc
=cut

package EEntity::EOperation::EStopNode;
use base "EEntity::EOperation";

use Kanopya::Exceptions;
use EEntity;
use Entity::ServiceProvider::Cluster;
use Entity::Host;

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;


=pod
=begin classdoc

@param cluster the cluster on which remove a node
@param host    the host corresponding to the node to remove

=end classdoc
=cut

sub check {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => $self->{context}, required => [ "cluster", "host" ]);
}


=pod
=begin classdoc

Ask to the cluster component if they are ready for th node removal

=end classdoc
=cut

sub prerequisites {
    my $self  = shift;
    my %args  = @_;
    my $delay = 10;

    my $cluster_id = $self->{context}->{cluster}->id;

    if (not $self->{context}->{cluster}->readyNodeRemoving(host => $self->{context}->{host})) {
        $log->debug("Cluster <$cluster_id > not ready for node removing, retrying in $delay seconds");
        return $delay;
    }

    $log->debug("Cluster <$cluster_id> ready for node removing, preparing StopNode.");
    return 0;
}

=pod
=begin classdoc

Stop the host, Set the node a as 'goingout'.

=end classdoc
=cut

sub execute {
    my $self = shift;
    $self->SUPER::execute();

    $self->{context}->{cluster}->stopNode(host => $self->{context}->{host});

    # Finaly halt the node
    $self->{context}->{host}->halt();

    $self->{context}->{host}->setNodeState(state => "goingout");
}


=pod
=begin classdoc

Restore the clutser and host states.

=end classdoc
=cut

sub cancel {
    my ($self, %args) = @_;
    $self->SUPER::finish(%args);

    $self->{context}->{cluster}->setState(state => 'up');
}

1;
