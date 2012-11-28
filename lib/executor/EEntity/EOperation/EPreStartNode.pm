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
use EFactory;
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


sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    General::checkParams(args => $self->{context}, required => [ "cluster", "host", "systemimage" ]);

    General::checkParams(args => $self->{params}, required => [ "node_number" ]);

    my $master_node_id = $self->{context}->{cluster}->getMasterNodeId();
    my $node_count = $self->{context}->{cluster}->getCurrentNodesCount();
    if (! $master_node_id && $node_count){
        $errmsg = "No master node when host <" . $self->{context}->{host}->id . "> migrating, pls wait...";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}

sub execute {
    my $self = shift;
    $self->SUPER::execute();

    my @components = $self->{context}->{cluster}->getComponents(category => "all",
                                                                order_by => "priority");
    $log->info('Inform cluster components about node addition');
    foreach my $component (@components) {
        EFactory::newEEntity(data => $component)->preStartNode(
            host    => $self->{context}->{host},
            cluster => $self->{context}->{cluster},
        );
    }

    # Define a hostname
    my $hostname = $self->{context}->{cluster}->getAttr(name => 'cluster_basehostname');
    if ($self->{context}->{cluster}->cluster_max_node > 1) {
        $hostname .=  $self->{params}->{node_number};
    }
    $self->{context}->{host}->setAttr(name => "host_hostname", value => $hostname);
    $self->{context}->{host}->save();

    $self->{context}->{host}->becomeNode(
        inside_id      => $self->{context}->{cluster}->id,
        master_node    => 0,
        systemimage_id => $self->{context}->{systemimage}->id,
        node_number    => $self->{params}->{node_number},
    );

    # Create the node working directory where generated files will be
    # stored.
    my $dir = $self->{config}->{clusters}->{directory};
    $dir .= '/' . $self->{context}->{cluster}->cluster_name;
    $dir .= '/' . $hostname;
    my $econtext = $self->getEContext();
    $econtext->execute(command => "mkdir -p $dir");

    $log->debug('Giving access to the system image to the node');

    # Here we compute an iscsi initiator name for the node
    my $date = today();
    my $year = $date->year;
    my $month = $date->month;
    if (length($month) == 1) {
        $month = '0' . $month;
    }

    my $initiatorname = 'iqn.' . $year . '-' . $month . '.';
    $initiatorname .= $self->{context}->{cluster}->cluster_name;
    $initiatorname .= '.' . $self->{context}->{host}->host_hostname;
    $initiatorname .= ':' . time();

    $self->{context}->{host}->setAttr(name  => "host_initiatorname",
                                      value => $initiatorname);
    $self->{context}->{host}->save();

    my $container_access = pop @{ $self->{context}->{systemimage}->container->getAccesses };
    my $export_manager = EFactory::newEEntity(data => $container_access->getExportManager);
    my $export = EFactory::newEEntity(data => $container_access);
    my $options = $self->{context}->{cluster}->cluster_si_shared ? "ro" : "rw";
    $export_manager->addExportClient(
        export  => $export,
        host    => $self->{context}->{host},
        options => $options
    );

    $self->{context}->{host}->setNodeState(state => "pregoingin");
}

sub _cancel {
    my $self = shift;

    if ($self->{context}->{cluster}) {
        my $hosts = $self->{context}->{cluster}->getHosts();
        if (! scalar keys %$hosts) {
            $self->{context}->{cluster}->setState(state => 'down');
        }
    }

    if ($self->{context}->{host}) {
        my $dir = $self->{config}->{clusters}->{directory};
        $dir .= '/' . $self->{context}->{cluster}->getAttr(name => 'cluster_name');
        $dir .= '/' . $self->{context}->{host}->getAttr(name => 'host_hostname');
        $self->getEContext->execute(command => "rm -r $dir");

        $self->{context}->{host}->setAttr(name  => 'host_hostname', value => undef);
        $self->{context}->{host}->setState(state => 'down');
        $self->{context}->{host}->stop();
    }
}

1;
