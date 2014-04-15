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
                         required => [ 'deployment_manager', 'node', 'systemimage' ],
                         optional => { 'hypervisor' => undef });

    General::checkParams(args     => $self->{params},
                         required => [ 'boot_policy' ],
                         optional => { 'deploy_on_disk' => 0, 'kernel_id' => undef });
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
        systemimage    => $self->{context}->{systemimage},
        boot_policy    => $self->{params}->{boot_policy},
        deploy_on_disk => $self->{params}->{deploy_on_disk},
        kernel_id      => $self->{params}->{kernel_id},
        hypervisor     => $self->{context}->{hypervisor},
        erollback      => $self->{erollback}
    );

    $self->{context}->{node}->setState(state => "goingin");
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
    if ($starting_time > $broken_time) {
        EEntity->new(entity => $self->{context}->{node}->host)->timeOuted();
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

    # If deployed on disk, remove the bost from teh dhcp to avoid the PXE
    # at the next reboot
    if ($self->{params}->{deploy_on_disk}) {
        # Check if the host has already been deployed
        my $hd = $self->{context}->{node}->host->find(related  => 'harddisks' ,
                                                      order_by => 'harddisk_device');

        if (! (defined $hd->deployed_on_id && $hd->deployed_on_id == $self->{context}->{node}->id)) {
            # Try connecting to the host, delay if it fails
            try {
                if ($args{node}->getEContext->execute(command => "true")->{exitcode}) {
                    throw Kanopya::Exception::Execution();
                }
            }
            catch ($err) {
                return $delay;
            }

            # Verify hostname
            my $theoricalhostname = $self->{context}->{node}->node_hostname;
            my $realhostname = $self->{context}->{node}->getEContext->execute(command => 'hostname -s');

            chomp($realhostname->{stdout});
            if ($theoricalhostname ne $realhostname->{stdout}) {
                throw Kanopya::Exception::Execution::OperationInterrupted(
                    error => "System hostname \"$realhostname->{stdout}\" is different than " .
                             "the database hostname for host \"$theoricalhostname\". " .
                             "Is PXE boot working properly ?"
                );
            }

            # Disable PXE boot but keep the host entry
            $hd->deployed_on_id($self->{context}->{node}->id);
            my $dhcp = EEntity->new(entity => $self->{context}->{deployment_manager}->dhcp_component);
            $dhcp->removeHost(host => $args{node}->host);
            $dhcp->addHost(host => $args{node}->host, pxe => 0);
            $dhcp->applyConfiguration();

            # Now reboot the host
            try {
                $args{node}->getEContext->execute(
                    command => "sync; echo 1 > /proc/sys/kernel/sysrq; echo b > /proc/sysrq-trigger"
                );
            }
            catch ($err) {
                $log->warn("Unable to reboot the host: $err");
            }

            return $delay;
        }
    }

    # Node is up
    $self->{context}->{node}->host->setState(state => "up");
    $self->{context}->{node}->setState(state => "in");

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
