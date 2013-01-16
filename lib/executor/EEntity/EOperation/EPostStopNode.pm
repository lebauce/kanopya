#    Copyright © 2009-2012 Hedera Technology SAS
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

package EEntity::EOperation::EPostStopNode;
use base "EEntity::EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Systemimage;
use EFactory;
use String::Random;

my $log = get_logger("");
my $errmsg;


sub check {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => $self->{context}, required => [ "cluster", "host" ]);
}

sub prerequisites {
    my $self  = shift;
    my %args  = @_;

    # Duration to wait before retrying prerequistes
    my $delay = 10;

    # Duration to wait for setting host broken
    my $broken_time = 240;

    my $cluster_id = $self->{context}->{cluster}->id;
    my $host_id    = $self->{context}->{host}->id;

    # Check how long the host is 'stopping'
    my @state = $self->{context}->{host}->getState;
    my $stopping_time = time() - $state[1];

    if($stopping_time > $broken_time) {
        $self->{context}->{host}->setState(state => 'broken');
    }

    my $node_ip = $self->{context}->{host}->adminIp;
    if (not $node_ip) {
        throw Kanopya::Exception::Internal(error => "Host <$host_id> has no admin ip.");
    }

    # Instanciate an econtext to try initiating an ssh connexion.
    eval {
        $self->{context}->{host}->getEContext;

        # Check if all host components are up.
        my @components = $self->{context}->{cluster}->getComponents(category => "all");
        foreach my $component (@components) {
            my $component_name = $component->component_type->component_name;
            $log->debug("Browse component: " . $component_name);
    
            my $ecomponent = EFactory::newEEntity(data => $component);
    
            if ($ecomponent->isUp(host => $self->{context}->{host}, cluster => $self->{context}->{cluster})) {
                $log->debug("Component <$component_name> on host <$host_id> from cluster <$cluster_id> up.");
                return $delay;
            }
        }
    };
    if ($@) {
        $log->debug("Could not connect to host <$host_id> from cluster <$cluster_id> with ip <$node_ip>.");
    }

    return $delay if $self->{context}->{host}->checkUp();

    $self->{context}->{host}->setState(state => "down");

    $log->info("Host <$host_id> in cluster <$cluster_id> is 'down', preparing PostStopNode.");
    return 0;
}

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    # Instanciate bootserver Cluster
    my $bootserver = Entity::ServiceProvider->get(id => $self->{config}->{cluster}->{bootserver});

    # Instanciate dhcpd component
    $self->{context}->{component_dhcpd}
        = EFactory::newEEntity(data => $bootserver->getComponent(name => "Dhcpd", version => "3"));
}

sub execute {
    my $self = shift;
    $self->SUPER::execute();
    $self->{context}->{host}->stop();

    # Remove Host from the dhcp
    eval {
        my $host_mac = $self->{context}->{host}->getPXEIface->getAttr(name => 'iface_mac_addr');
        if ($host_mac) {
            my $subnet = $self->{context}->{component_dhcpd}->getInternalSubNetId();

            my $hostid = $self->{context}->{component_dhcpd}->getHostId(
                             dhcpd3_subnet_id         => $subnet,
                             dhcpd3_hosts_mac_address => $host_mac
                         );

            $self->{context}->{component_dhcpd}->removeHost(dhcpd3_subnet_id => $subnet,
                                                            dhcpd3_hosts_id  => $hostid);
            $self->{context}->{component_dhcpd}->generate();
            $self->{context}->{component_dhcpd}->reload();
        }
    };
    if ($@) {
        $log->warn("Could not remove from DHCP configuration, the cluster may not be using PXE");
    }

    # remove the node working directory where generated files are
    # stored.
    my $dir = $self->{config}->{clusters}->{directory};
    $dir .= '/' . $self->{context}->{cluster}->getAttr(name => 'cluster_name');
    $dir .= '/' . $self->{context}->{host}->getAttr(name => 'host_hostname');
    my $econtext = $self->getEContext();
    $econtext->execute(command => "rm -r $dir");

    $self->{context}->{host}->setAttr(name => "host_hostname", value => undef);
    $self->{context}->{host}->setAttr(name => "host_initiatorname", value => undef);

    my $systemimage_name = $self->{context}->{cluster}->cluster_name;
    $systemimage_name .= '_' . $self->{context}->{host}->getNodeNumber();

    # Finally save the host
    $self->{context}->{host}->save();

    # Update the user quota on ram and cpu
    $self->{context}->{cluster}->user->releaseQuota(
        resource => 'ram',
        amount   => $self->{context}->{host}->host_ram,
    );
    $self->{context}->{cluster}->user->releaseQuota(
        resource => 'cpu',
        amount   => $self->{context}->{host}->host_core,
    );

    $self->{context}->{host}->stopToBeNode();

    $log->info('Processing cluster components configuration for this node');
    $self->{context}->{cluster}->postStopNode(host => $self->{context}->{host});

    # delete the image if persistent policy not set
    if($self->{context}->{cluster}->cluster_si_persistent eq '0') {
        $log->info("cluster image persistence is not set, deleting $systemimage_name");
        eval {
            my $entity = Entity::Systemimage->find(hash => { systemimage_name => $systemimage_name });
            $self->{context}->{systemimage} = EFactory::newEEntity(data => $entity);   
        };
        if ($@) {
            $log->debug("Could not find systemimage with name <$systemimage_name> for removal.");
        } 
        $self->{context}->{systemimage}->deactivate(erollback => $self->{erollback});
        $self->{context}->{systemimage}->remove(erollback => $self->{erollback});

    } else {
        $log->info("cluster image persistence is set, keeping $systemimage_name image");
    }
}

sub finish {
    my $self = shift;

    my @cluster_state = $self->{context}->{cluster}->getState;
    my $nbnodes = scalar(@{ $self->{context}->{cluster}->getHosts() });

    # If the cluster has no node any more, it has been properly stoped
    if ($nbnodes == 0) {
        $self->{context}->{cluster}->setState(state => "down");
    }

    # If a stoping cluster has one node left, this is must be the master node
    if ($cluster_state[0] eq 'stopping' and $nbnodes == 1) {
        $self->{context}->{cluster}->removeNode(
            host_id => $self->{context}->{cluster}->getMasterNodeId()
        );
    }
}


=head1 DIAGNOSTICS

Exceptions are thrown when mandatory arguments are missing.
Exception : Kanopya::Exception::Internal::IncorrectParam

=head1 CONFIGURATION AND ENVIRONMENT

This module need to be used into Kanopya environment. (see Kanopya presentation)
This module is a part of Administrator package so refers to Administrator configuration

=head1 DEPENDENCIES

This module depends of 

=over

=item KanopyaException module used to throw exceptions managed by handling programs

=item Entity::Component module which is its mother class implementing global component method

=back

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to <Maintainer name(s)> (<contact address>)

Patches are welcome.

=head1 AUTHOR

<HederaTech Dev Team> (<dev@hederatech.com>)

=head1 LICENCE AND COPYRIGHT

Kanopya Copyright (C) 2009-2012 Hedera Technology.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301 USA.

=cut

1;
