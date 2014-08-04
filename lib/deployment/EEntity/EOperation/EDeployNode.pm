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

use TryCatch;
use Log::Log4perl "get_logger";
use Date::Simple (':all');

my $log = get_logger("");


=pod
=begin classdoc

@param deployment_manager the deployment component used to deploy the node
@param node the node to deploy
@param systemimage the systemiage to use to deploy the node
@param boot_policy, the boot policy for the deplyoment

@optional hypervisor the hypervisor to use for virtuals nodes
@optional kernel_id force the kernel to use
@optional deploy_on_disk activate the on disk deployment

=end classdoc
=cut

sub check {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => $self->{context},
                         required => [ 'deployment_manager', 'node' ],
                         optional => { 'hypervisor' => undef });

    General::checkParams(args => $self->{params}, optional => { 'deploy_on_disk' => 0  });
}


=pod
=begin classdoc

Ask to the deplyment manager to deploy the node

=end classdoc
=cut

sub execute {
    my ($self, %args) = @_;

    $self->{context}->{deployment_manager}->deployNode(
        node           => $self->{context}->{node},
        hypervisor     => $self->{context}->{hypervisor},
        erollback      => $self->{erollback},
        %{ $self->{params} }
    );
}

=pod
=begin classdoc

Wait for the to be up.

=end classdoc
=cut

sub postrequisites {
    my ($self, %args) = @_;

    return $self->{context}->{deployment_manager}->checkNodeUp(
        node           => $self->{context}->{node},
        # deploy_on_disk => $self->{params}->{deploy_on_disk},
        erollback      => $self->{erollback},
        %{ $self->{params} }
    );
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
