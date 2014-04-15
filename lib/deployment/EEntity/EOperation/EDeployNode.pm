#    Copyright © 2009-2013 Hedera Technology SAS
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

=pod
=begin classdoc

Deploy a node using given host, disk, and export managers.

@since    2014-Apr-11
@instance hash
@self     $self

=end classdoc
=cut

package EEntity::EOperation::EDeployNode;
use base EEntity::EOperation;

use strict;
use warnings;

use General;
use Kanopya::Exceptions;

use Log::Log4perl "get_logger";
use Date::Simple (':all');

my $log = get_logger("");


=pod
=begin classdoc

@param deployment_manager the deployment component used to deploy the node
@param node the node to deploy
@param systemimage the systemiage to use to deploy the node
@param boot_mode, the boot mode for the deplyoment

@optional hypervisor the hypervisor to use for virtuals nodes
@optional kernel_id force the kernel to use

=end classdoc
=cut

sub check {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => $self->{context},
                         required => [ 'deployment_manager', 'node', 'systemimage' ],
                         optional => { 'hypervisor' => undef });

    General::checkParams(args     => $self->{params},
                         required => [ 'boot_mode' ],
                         optional => { 'kernel_id' => undef });
}


=pod
=begin classdoc

Ask to the deplyment manager to deploy the node

=end classdoc
=cut

sub execute {
    my ($self, %args) = @_;

    $self->{context}->{deployment_manager}->deployNode(
        node        => $self->{context}->{node},
        systemimage => $self->{context}->{systemimage},
        boot_mode   => $self->{params}->{boot_mode},
        kernel_id   => $self->{params}->{kernel_id},
        hypervisor  => $self->{context}->{hypervisor},
        erollback   => $self->{erollback}
    );

    $self->{context}->{host}->setNodeState(state => "goingin");
}

=pod
=begin classdoc

Wait for the to be up.

=end classdoc
=cut

sub postrequisites {
    my ($self, %args) = @_;

    # Duration to wait before retrying prerequistes
    my $delay = 10;

    # Duration to wait for setting host broken
    my $broken_time = 240;

    # Check how long the host is 'starting'
    my @state = $self->{context}->{node}->host->getState;
    my $starting_time = time() - $state[1];
    if($starting_time > $broken_time) {
        $self->{context}->{node}->host->timeOuted();
    }

    my $node_ip = $self->{context}->{node}->host->adminIp;
    if (not $node_ip) {
        throw Kanopya::Exception::Internal(
                  error => "Host \"" . $self->{context}->{node}->host->label .  "\" has no admin ip."
              );
    }

    if (! EEntity->new(entity => $self->{context}->{node}->host)->checkUp()) {
        $log->info("Host \"" . $self->{context}->{node}->host->label .
                   "\" not yet reachable at <$node_ip>");
        return $delay;
    }

    # Check if all host components are up.
    if (not $self->{context}->{node}->checkComponents()) {
        return $delay;
    }

    # Node is up
    $self->{context}->{node}->host->setState(state => "up");
    $self->{context}->{node}->host->setNodeState(state => "in");

    $log->info("Host \"" . $self->{context}->{node}->host->label .  "\" is 'up'");

    return 0;
}


=pod
=begin classdoc

Removing objects from the context

=end classdoc
=cut

sub finish {
    my ($self, %args) = @_;

    delete $self->{context}->{deployment_manager};
    # delete $self->{context}->{node};
    delete $self->{context}->{systemimage};
}


=pod
=begin classdoc

Try to stop the node that has been possibly started.

=end classdoc
=cut

sub cancel {
    my ($self, %args) = @_;

    eval {
        EEntity->new(entity => $self->{context}->{node}->host)->halt();
    };
    if ($@) {
        $log->warn($@);
    }
    eval {
        EEntity->new(entity => $self->{context}->{node}->host)->stop();
    };
    if ($@) {
        $log->warn($@);
    }
}

1;
