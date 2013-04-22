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

package EEntity::EOperation::EPreStartNode;
use base "EEntity::EOperation";

use Kanopya::Exceptions;
use EEntity;
use Entity::Host;
use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use String::Random;
use Date::Simple (':all');
use Template;

my $log = get_logger("");
my $errmsg;

sub execute {
    my $self = shift;
    $self->SUPER::execute();

    my @components = $self->{context}->{cluster}->getComponents(category => "all",
                                                                order_by => "priority");

    $log->info('Inform cluster components about node addition');
    foreach my $component (@components) {
        EEntity->new(data => $component)->preStartNode(
            host    => $self->{context}->{host},
            cluster => $self->{context}->{cluster},
        );
    }

    # Define a hostname
    my $hostname = $self->{context}->{cluster}->cluster_basehostname;
    if ($self->{context}->{cluster}->cluster_max_node > 1) {
        $hostname .=  $self->{params}->{node_number};
    }

    # Register the node in the cluster
    my $params = { host        => $self->{context}->{host},
                   systemimage => $self->{context}->{systemimage},
                   number      => $self->{params}->{node_number},
                   hostname    => $hostname };

    # If components to install on the node defined,
    if ($self->{params}->{component_types}) {
        $params->{components} = $self->{context}->{cluster}->searchRelated(
                                    filters => [ 'components' ],
                                    hash    => {
                                        'component_type.component_type_id' => $self->{params}->{component_types}
                                    }
                                );
    }
    $self->{context}->{cluster}->registerNode(%$params);

    # Create the node working directory where generated files will be
    # stored.
    my $dir = $self->_executor->getConf->{clusters_directory};
    $dir .= '/' . $self->{context}->{cluster}->cluster_name;
    $dir .= '/' . $hostname;
    my $econtext = $self->getEContext();
    $econtext->execute(command => "mkdir -p $dir");

    # Here we compute an iscsi initiator name for the node
    my $date = today();
    my $year = $date->year;
    my $month = $date->month;
    if (length($month) == 1) {
        $month = '0' . $month;
    }

    my $initiatorname = 'iqn.' . $year . '-' . $month . '.';
    $initiatorname .= $self->{context}->{cluster}->cluster_name;
    $initiatorname .= '.' . $self->{context}->{host}->node->node_hostname;
    $initiatorname .= ':' . time();

    $self->{context}->{host}->setAttr(name  => "host_initiatorname",
                                      value => $initiatorname,
                                      save  => 1);

    # For each container accesses of the system image, add an export client
    my $options = $self->{context}->{cluster}->cluster_si_shared ? "ro" : "rw";
    for my $container_access ($self->{context}->{systemimage}->container_accesses) {
        my $export_manager = EEntity->new(data => $container_access->getExportManager);
        my $export         = EEntity->new(data => $container_access);

        $export_manager->addExportClient(
            export  => $export,
            host    => $self->{context}->{host},
            options => $options
        );
    }

    $self->{context}->{host}->setNodeState(state => "pregoingin");
}

sub _cancel {
    my $self = shift;

    if ($self->{context}->{cluster}) {
        if (! scalar(@{ $self->{context}->{cluster}->getHosts() })) {
            $self->{context}->{cluster}->setState(state => 'down');
        }
    }

    if ($self->{context}->{host}) {
        if (defined $self->{context}->{host}->node) {
            my $dir = $self->_executor->getConf->{clusters_directory};
            $dir .= '/' . $self->{context}->{cluster}->cluster_name;
            $dir .= '/' . $self->{context}->{host}->node->node_hostname;
            $self->getEContext->execute(command => "rm -r $dir");

            $self->{context}->{host}->node->setAttr(name  => 'node_hostname', value => undef, save => 1);
        }

        $self->{context}->{host}->stop();
        $self->{context}->{host}->setState(state => 'down');
    }
}

1;
