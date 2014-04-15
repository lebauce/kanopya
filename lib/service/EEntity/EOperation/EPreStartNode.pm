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
use Entity::Host;

use Log::Log4perl "get_logger";
use Data::Dumper;
use String::Random;
use Template;

my $log = get_logger("");
my $errmsg;


=pod
=begin classdoc

@param cluster     the cluster to add node
@param host        the host selected to be registred as node
@param systemimage the system image of the node
@param node_number the number of the new node

=end classdoc
=cut

sub check {
    my ($self, %args) = @_;

    General::checkParams(args => $self->{context}, required => [ "cluster", "host", "systemimage" ]);

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
            host    => $self->{context}->{host},
            cluster => $self->{context}->{cluster},
        );
    }

    # Define a hostname
    my $hostname = $self->{context}->{cluster}->getNodeHostname(
                       node_number => $self->{params}->{node_number}
                   );

    # Register the node in the cluster
    my $params = { host        => $self->{context}->{host},
                   systemimage => $self->{context}->{systemimage},
                   number      => $self->{params}->{node_number},
                   hostname    => $hostname };

    # If components to install on the node defined,
    if ($self->{params}->{component_types}) {
        $params->{components}
            = $self->{context}->{cluster}->search(
                  related => 'components',
                  hash    => {
                      'component_type.component_type_id' => $self->{params}->{component_types}
                  }
              );
    }
    $self->{context}->{cluster}->registerNode(%$params);

    # Create the node working directory where generated files will be stored.
    my $dir = $self->_executor->getConf->{clusters_directory} . '/' . $hostname;
    $self->getEContext->execute(command => "mkdir -p $dir");
}


=pod
=begin classdoc

Ask to the cluster component if they are ready for the node addition.

=end classdoc
=cut

sub postrequisites {
    my $self  = shift;
    my %args  = @_;
    my $delay = 10;

    # Ask to all cluster component if they are ready for node addition.
    if (! $self->{context}->{cluster}->readyNodeAddition(host => $self->{context}->{host})) {
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

    $self->{context}->{host}->setNodeState(state => "pregoingin");

    # Ask to the DeploymentManager to deploy the node from the systemimage
    $self->{context}->{cluster}->getManager(manager_type => 'DeploymentManager')->deployNode(
        node           => $self->{context}->{host}->node,
        systemimage    => $self->{context}->{systemimage},
        boot_policy    => $self->{context}->{cluster}->cluster_boot_policy,
        kernel_id      => $self->{context}->{cluster}->kernel_id,
        workflow       => $self->workflow,
        # Add the hosting params for deploy_on_disk parameter
        %{ $self->{context}->{cluster}->getManagerParameters(manager_type => 'HostManager') }
    );
}


=pod
=begin classdoc

Unregister the node.

=end classdoc
=cut

sub cancel {
    my ($self, %args) = @_;

    if (defined $self->{context}->{host}->node) {
        my $dir = $self->_executor->getConf->{clusters_directory};
        $dir .= '/' . $self->{context}->{host}->node->node_hostname;
        $self->getEContext->execute(command => "rm -r $dir");

        $self->{context}->{cluster}->unregisterNode(node => $self->{context}->{host}->node);
    }
}

1;
