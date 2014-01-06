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

Configure the system image of the node, and start it.

@since    2012-Aug-20
@instance hash
@self     $self

=end classdoc
=cut

package EEntity::EOperation::EStartNode;
use base "EEntity::EOperation";

use strict;
use warnings;

use Kanopya::Exceptions;
use EEntity;
use EEntity;
use Entity::ServiceProvider;
use Entity::ServiceProvider::Cluster;
use Entity::Host;
use Entity::Kernel;
use General;

use Data::Dumper;
use Log::Log4perl "get_logger";
use Date::Simple (':all');

my $log = get_logger("");


=pod
=begin classdoc

@param cluster the cluster to add node
@param host    the host selected to be registred as node

=end classdoc
=cut

sub check {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => $self->{context}, required => [ "cluster", "host" ]);
}


=pod
=begin classdoc

Ask to the cluster component if they are ready for the node addition.

=end classdoc
=cut

sub prerequisites {
    my $self  = shift;
    my %args  = @_;
    my $delay = 10;

    my $cluster_id = $self->{context}->{cluster}->id;
    my $host_id    = $self->{context}->{host}->id;

    # Ask to all cluster component if they are ready for node addition.
    my @components = $self->{context}->{cluster}->getComponents(category => "all");
    foreach my $component (@components) {
        my $ready = EEntity->new(entity => $component)->readyNodeAddition(host_id => $host_id);
        if (not $ready) {
            $log->info("Component $component not ready for node addition");
            return $delay;
        }
    }

    $log->debug("Cluster <$cluster_id> ready for node addition");
    return 0;
}


=pod
=begin classdoc

Mount the system image on the executor, configure the network, the components,
the boot configuration, and start the node.

=end classdoc
=cut

sub execute {
    my ($self, %args) = @_;
    $self->SUPER::execute(%args);

    # Apply puppet configuration
    my $kanopya = EEntity->new(entity => Entity::ServiceProvider::Cluster->getKanopyaCluster);
    $kanopya->reconfigure(tags => [ "kanopya::operation::startnode" ]);

    # Finally we start the node
    $self->{context}->{host} = $self->{context}->{host}->start(
                                   erollback  => $self->{erollback},
                                   hypervisor => $self->{context}->{hypervisor}, # Required for vm add only
                                   cluster    => $self->{context}->{cluster}
                               );

    eval { $self->{params}->{vminfo} = $self->{context}->{host}->getVmInfo(); };
}


=pod
=begin classdoc

Update the node state.

=end classdoc
=cut

sub finish {
    my ($self, %args) = @_;
    $self->SUPER::finish(%args);

    $self->{context}->{host}->setNodeState(state => "goingin");

    delete $self->{context}->{systemimage};
}


sub cancel {
    my ($self, %args) = @_;

     $log->debug(Dumper $self->{params}->{vminfo});

    if (defined $self->{context}->{host}) {
        if ($self->{context}->{host}->isa('EEntity::EHost::EVirtualMachine')) {
            eval {
                $self->{context}->{host}->getHostManager->promoteVm(
                    host => $self->{context}->{host}->_entity,
                    %{$self->{params}->{vminfo}}
                );
            }
        }

        eval {
            $self->{context}->{host}->reload->halt();
        };
        if ($@) {
            $log->warn($@);
        }
        eval {
            $self->{context}->{host}->reload->stop();
        };
        if ($@) {
            $log->warn($@);
        }
    }
}

1;
