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

=pod
=begin classdoc

Register the new node.

@since    2012-Aug-20
@instance hash
@self     $self

=end classdoc
=cut

package EEntity::EOperation::EPreStartNode;
use base "EEntity::EOperation";

use strict;
use warnings;

use Kanopya::Exceptions;
use EEntity;

use TryCatch;
use Hash::Merge;
use Log::Log4perl "get_logger";
use Data::Dumper;
use String::Random;
use Template;

my $log = get_logger("");

my $merge = Hash::Merge->new('RIGHT_PRECEDENT');


=pod
=begin classdoc

@param cluster     the cluster to add node
@param node        the node to start
@param systemimage the system image of the node
@param node_number the number of the new node

=end classdoc
=cut

sub check {
    my ($self, %args) = @_;

    General::checkParams(args => $self->{context}, required => [ "cluster", "node", "systemimage" ]);

    General::checkParams(args => $self->{params}, required => [ "node_number" ]);
}


=pod
=begin classdoc

Register the node.

=end classdoc
=cut

sub execute {
    my ($self, %args) = @_;

    my @components = $self->{context}->{cluster}->getComponents(category => "all",
                                                                order_by => "priority");

    foreach my $component (@components) {
        EEntity->new(data => $component)->preStartNode(
            node    => $self->{context}->{node},
            cluster => $self->{context}->{cluster},
        );
    }
}


=pod
=begin classdoc

Ask to the cluster component if they are ready for the node addition.

=end classdoc
=cut

sub postrequisites {
    my ($self, %args) = @_;
    my $delay = 10;

    # Ask to all cluster component if they are ready for node addition.
    if (! $self->{context}->{cluster}->readyNodeAddition(node => $self->{context}->{node})) {
        $log->debug("Cluster <" . $self->{context}->{cluster}->label . 
                    "> not ready for node addition, retrying in $delay seconds");
        return $delay;
    }

    $log->info("Cluster <" . $self->{context}->{cluster}->id . "> ready for node addition");
    return 0;
}


=pod
=begin classdoc

Update the node state.

=end classdoc
=cut

sub finish {
    my ($self, %args) = @_;

    $self->{context}->{node}->setState(state => "pregoingin");

    # Ask to the DeploymentManager to deploy the node from the systemimage
    # Merge all manager parameters for the deployment manager
    my $managers_params = $self->{context}->{cluster}->getManagerParameters();
    $self->{context}->{cluster}->getManager(manager_type => 'DeploymentManager')->deployNode(
        node            => $self->{context}->{node},
        boot_manager    => $self->{context}->{cluster}->getManager(manager_type => 'BootManager'),
        network_manager => $self->{context}->{cluster}->getManager(manager_type => 'NetworkManager'),
        systemimage     => $self->{context}->{systemimage},
        kernel_id       => $self->{context}->{cluster}->kernel_id,
        workflow        => $self->workflow,
        %{ $managers_params }
    );
}

1;
