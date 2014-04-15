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

Stop the host corresponding to the node to release.

@since    2012-Aug-20
@instance hash
@self     $self

=end classdoc
=cut

package EEntity::EOperation::EReleaseNode;
use base EEntity::EOperation;

use Kanopya::Exceptions;


use strict;
use warnings;

use TryCatch;
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");


=pod
=begin classdoc

@param node the node to release

=end classdoc
=cut

sub check {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => $self->{context}, required => [ "deployment_manager", "node" ]);
}


=pod
=begin classdoc

Stop the host, set the node a as 'goingout'.

=end classdoc
=cut

sub execute {
    my $self = shift;

    $self->{context}->{deployment_manager}->releaseNode(node => $self->{context}->{node});

    $self->{context}->{node}->host->setNodeState(state => "goingout");
}


=pod
=begin classdoc

Wait for the host shutdown properly.

=end classdoc
=cut

sub postrequisites {
    my $self  = shift;
    my %args  = @_;

    # Duration to wait before retrying prerequistes
    my $delay = 10;

    # Duration to wait for setting host broken
    my $broken_time = 240;

    # Check how long the host is 'stopping'
    my @state = $self->{context}->{host}->getState;
    my $stopping_time = time() - $state[1];

    if($stopping_time > $broken_time) {
        $self->{context}->{host}->setState(state => 'broken');
    }

    my $node_ip = $self->{context}->{host}->adminIp;
    if (not $node_ip) {
        throw Kanopya::Exception::Internal(
                  error => "Host " . $self->{context}->{node}->label .  " has no admin ip."
              );
    }

    # Instanciate an econtext to try initiating an ssh connexion.
    try {
        $self->{context}->{host}->getEContext;

        # Check if all host components are down.
        my @components = $self->{context}->{cluster}->getComponents(category => "all");
        foreach my $component (map { EEntity->new(data => $_) } @components) {
            if ($component->isUp(host => $self->{context}->{host})) {
                $log->info("Component " . $component->label .
                           " still up on node " . $self->{context}->{node}->label);
                return $delay;
            }
            $log->info("Component " . $component->label . " do not respond any more");
        }
    }
    catch (Kanopya::Exception::Network $err) {
        $log->info("Node " . $self->{context}->{node}->label . " do not repond to ssh any more");
    }
    catch (Kanopya::Exception $err) {
        $err->rethrow();
    }
    catch ($err) {
        throw Kanopya::Exception::Execution(error => $err);
    }

    # Finally ask to the host manager to check if node is still power on
    try {
        if ($self->{context}->{host}->checkUp()) {
            return $delay;
        }
    }
    catch {
        # Check test failed, considering the host down
    }

    # Stop the host
    $self->{context}->{host}->stop();

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
    delete $self->{context}->{node};
}

1;
