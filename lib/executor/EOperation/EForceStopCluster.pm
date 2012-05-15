# EForceStopCluster.pm - Operation class node removing from cluster operation

#    Copyright © 2011 Hedera Technology SAS
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
# Created 14 july 2010

=head1 NAME

EOperation::EForceStopCluster - Operation class implementing node removing operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement node removing operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EForceStopCluster;
use base "EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;

use Kanopya::Exceptions;
use Entity;

use EFactory;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';

=head2 prepare

    $op->prepare();

=cut

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    General::checkParams(args => $self->{context}, required => [ "cluster" ]);

    # Instanciate bootserver Cluster
    my $bootserver = Entity->get(id => $self->{config}->{cluster}->{bootserver});

    # Instanciate dhcpd component.
    $self->{context}->{component_dhcpd}
        = EFactory::newEEntity(
              data => $bootserver->getComponent(name => "Dhcpd", version => "3")
          );
}

sub execute {
    my $self = shift;
    $self->SUPER::execute();

    my $nodes = $self->{context}->{cluster}->getHosts();
    my $subnet = $self->{context}->{component_dhcpd}->getInternalSubNetId();

    foreach my $key (keys %$nodes) {
        my $node = $nodes->{$key};
        eval {
            # Halt Node
            my $ehost = EFactory::newEEntity(data => $node);
            $ehost->halt();
        };
        if ($@) {
            my $error = $@;
            $errmsg = "Problem with node <" . $node->getAttr(name=>"host_id").
                      "> during force stop cluster : $error";
            $log->info($errmsg);
        }

        eval {
            # Update Dhcp component conf
            my $host_mac = $node->getPXEIface->getAttr(name => 'iface_mac_addr');
            if ($host_mac) {
	            my $hostid = $self->{context}->{component_dhcpd}->getHostId(
	                             dhcpd3_subnet_id         => $subnet,
	                             dhcpd3_hosts_mac_address => $host_mac
	                         );

	            $self->{context}->{component_dhcpd}->removeHost(dhcpd3_subnet_id => $subnet,
	                                                            dhcpd3_hosts_id  => $hostid);
            }
        };
        if ($@) {
            my $error = $@;
            $errmsg = "Problem with node <" . $node->getAttr(name=>"host_id").
                      "> during dhcp configuration update : $error";
            $log->info($errmsg);
        }

        # component migration
        my $components = $self->{context}->{cluster}->getComponents(category => "all");
        $log->info('Processing cluster components quick remove for node <' .
                   $node->getAttr(name => 'host_id') . '>');

        foreach my $i (keys %$components) {
            my $tmp = EFactory::newEEntity(data => $components->{$i});
            $log->debug("component is " . ref($tmp));
            $tmp->cleanNode(
                host => $node, mount_point => '', cluster => $self->{context}->{cluster}
            );
        }

        $node->setAttr(name => "host_hostname", value => undef);
        $node->setAttr(name => "host_initiatorname", value => undef);

        # finaly save the host
        $node->save();

        $node->stopToBeNode(cluster_id => $self->{context}->{cluster}->getAttr(name => "cluster_id"));
    }

    # Generate and reload Dhcp conf
    $self->{context}->{component_dhcpd}->generate();
    $self->{context}->{component_dhcpd}->reload();

    $self->{context}->{cluster}->setState(state => "down");
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
