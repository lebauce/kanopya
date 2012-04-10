# Copyright © 2010-2012 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package EOperation::EAddNode;
use base "EOperation";

use strict;
use warnings;

use Kanopya::Exceptions;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Masterimage;
use Entity::Systemimage;
use Entity::Host;

use Log::Log4perl "get_logger";
my $log = get_logger("executor");
my $errmsg;

=head2 prepare

    $op->prepare();

=cut

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    General::checkParams(args => \%args, required => [ "internal_cluster" ]);

    my $params = $self->_getOperation()->getParams();

    General::checkParams(args => $params, required => [ "cluster_id" ]);

    $self->{_objs} = {};

    # Get cluster to start from param
    $self->{_objs}->{cluster} = Entity::ServiceProvider::Inside::Cluster->get(
                                    id => $params->{cluster_id}
                                );

    # Get the masterimage for node systemimage creation.
    $self->{_objs}->{masterimage} = Entity::Masterimage->get(
                                        id => $self->{_objs}->{cluster}->getAttr(name => 'masterimage_id')
                                    );

    # Get the disk manager for disk creation
    my $disk_manager = Entity->get(id => $self->{_objs}->{cluster}->getAttr(name => 'disk_manager_id'));
    $self->{_objs}->{edisk_manager} = EFactory::newEEntity(data => $disk_manager);

    # Get the export manager for disk creation
    my $export_manager = Entity->get(id => $self->{_objs}->{cluster}->getAttr(name => 'export_manager_id'));
    $self->{_objs}->{eexport_manager} = EFactory::newEEntity(data => $export_manager);

    # Check if a host is specified.
    if (defined $params->{host_id}) {
        $self->{_objs}->{host} = Entity::Host->get(id => $params->{host_id});

        my $host_manager_id = $self->{_objs}->{host}->getAttr(name => 'host_manager_id');
        my $cluster_host_manager_id = $self->{_objs}->{cluster}->getAttr(name => "host_manager_id");

        # Check if the specified host is managed by the cluster host manager
        if ($host_manager_id != $cluster_host_manager_id) {
            $errmsg = "Specified host <$args{host_id}>, is not managed by the same " .
                      "host manager than the cluster one (<$host_manager_id>)" .
                      " ne <$cluster_host_manager_id).";
            throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
        }
    }

    $params->{node_number} = $self->{_objs}->{cluster}->getNewNodeNumber();
    $log->debug("Node number for this new node: $params->{node_number} ");

    my $systemimage_name = $self->{_objs}->{cluster}->getAttr(name => 'cluster_name') . '_' .
                           $params->{node_number};

    # Check for existing systemimage for this node.
    my $existing_image;
    eval {
        $existing_image = Entity::Systemimage->find(hash => {systemimage_name => $systemimage_name});
    };

    # If systemimage_id defined, force to use it.
    if (defined $params->{systemimage_id}) {
        $self->{_objs}->{systemimage} = Entity::Systemimage->get(id => $params->{systemimage_id});
    }
    # If systemimage already exist for this node, use it.
    elsif ($existing_image) {
        $log->info("Using existing systemimage instance <$systemimage_name>");
        $self->{_objs}->{systemimage} = $existing_image;
    }
    # Else if it is the firest node, or the cluster si policy is dedicated, create a new one.
    elsif (($params->{node_number} == 1) or (not $self->{_objs}->{cluster}->getAttr(name => 'cluster_si_shared'))) {
        $log->info("Create new systemimage instance <$systemimage_name>");

        my $systemimage_desc = 'System image for node ' . $params->{node_number}  .' in cluster ' .
                               $self->{_objs}->{cluster}->getAttr(name => 'cluster_name') . '.';

        eval {
           $self->{_objs}->{systemimage} = Entity::Systemimage->new(
                systemimage_name => $systemimage_name,
                systemimage_desc => $systemimage_desc,
           );
        };
        if($@) {
            throw Kanopya::Exception::Internal::WrongValue(error => $@);
        }
        $params->{create_systemimage} = 1;
    }
    # Else if it is the firest node, or the cluster si policy is dedicated, create a new one.
    else {
        $self->{_objs}->{systemimage} = $self->{_objs}->{cluster}->getMasterNodeSystemimage;
    }

    # Get contexts
    my $exec_cluster
        = Entity::ServiceProvider::Inside::Cluster->get(id => $args{internal_cluster}->{executor});
    $self->{executor}->{econtext} = EFactory::newEContext(ip_source      => $exec_cluster->getMasterNodeIp(),
                                                          ip_destination => $exec_cluster->getMasterNodeIp());
    $self->{params} = $params;
}

sub execute {
    my $self = shift;
    $self->SUPER::execute();

    if (not defined $self->{_objs}->{host}) {
        # Just call Master node addition, other node will be add by the state manager
        my $ecluster = EFactory::newEEntity(data => $self->{_objs}->{cluster});
        $self->{_objs}->{host} = $ecluster->addNode(econtext => $self->{executor}->{econtext});
    }
    $self->{_objs}->{host}->setState(state => "locked");

    my $esystemimage = EFactory::newEEntity(data => $self->{_objs}->{systemimage});

    # Create system image for node if required.
    if ($self->{params}->{create_systemimage}) {
        $esystemimage->createFromMasterimage(
            masterimage    => $self->{_objs}->{masterimage},
            edisk_manager  => $self->{_objs}->{edisk_manager},
            manager_params => $self->{_objs}->{cluster}->getManagerParameters(manager_type => 'disk_manager'),
            econtext       => $self->{executor}->{econtext},
            erollback      => $self->{erollback},
        );
    }

    # Export system image for node if required.
    if (not $self->{_objs}->{systemimage}->getAttr(name => 'active')) {
        $esystemimage->activate(
            eexport_manager => $self->{_objs}->{eexport_manager},
            manager_params  => $self->{_objs}->{cluster}->getManagerParameters(manager_type => 'export_manager'),
            econtext        => $self->{executor}->{econtext},
            erollback       => $self->{erollback}
        );
        $self->{params}->{systemimage_id} = $self->{_objs}->{systemimage}->getAttr(name => 'systemimage_id');
    }

    $log->debug("New Operation PreStartNode");
    Operation->enqueue(
        priority => 200,
        type     => 'PreStartNode',
        params   => {
            cluster_id     => $self->{_objs}->{cluster}->getAttr(name => 'cluster_id'),
            host_id        => $self->{_objs}->{host}->getAttr(name => 'host_id'),
            systemimage_id => $self->{_objs}->{systemimage}->getAttr(name => 'systemimage_id'),
            node_number    => $self->{params}->{node_number},
        }
    );
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010-2012 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
