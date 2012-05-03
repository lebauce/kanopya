# EPostStopNode.pm - Operation class node removing from cluster operation

#    Copyright © 2009-2012 Hedera Technology SAS
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

EOperation::EPostStopNode - Operation class implementing node removing operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement node removing operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EPostStopNode;
use base "EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Systemimage;
use EFactory;
use String::Random;
my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';

my $config = {
    INCLUDE_PATH => '/templates/internal/',
    INTERPOLATE  => 1,               # expand "$var" in plain text
    POST_CHOMP   => 0,               # cleanup whitespace 
    EVAL_PERL    => 1,               # evaluate Perl code blocks
    RELATIVE     => 1,               # desactive par defaut
};

sub checkOp{
    my $self = shift;
    my %args = @_;
    
    if($self->{_objs}->{host}->getAttr(name => 'host_state') =~ /^stopping:/) {
        my $msg = "Node is still in stopping state.";
        $log->error($msg);
        throw Kanopya::Exception::Execution::OperationReported(error => $msg);
    }
}

=head2 prepare

    $op->prepare();

=cut

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    $log->info("Operation preparation");

    General::checkParams(args => \%args, required => ["internal_cluster"]);

    my $params = $self->_getOperation()->getParams();

    General::checkParams(args => $params, required => [ "cluster_id", "host_id" ]);

    # Instantiate host and so check if exists
    $log->debug("checking host existence with id <$params->{host_id}>");
    eval {
        $self->{_objs}->{host} = Entity::Host->get(id => $params->{host_id});
    };
    if($@) {
        $errmsg = "EOperation::EPostStopNode->prepare : host_id $params->{host_id} does not found";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    # Cluster instantiation
    $log->debug("checking cluster existence with id <$params->{cluster_id}>");
    eval {
        $self->{_objs}->{cluster} = Entity::ServiceProvider::Inside::Cluster->get(
                                        id => $params->{cluster_id}
                                    );
    };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::EPostStopNode->prepare : cluster_id $params->{cluster_id} " .
                  "could not be found\n" . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    # Get cluster components Entities
    $log->debug("Load all component from cluster");
    $self->{_objs}->{components} = $self->{_objs}->{cluster}->getComponents(category => "all");
    
    eval {
        $self->checkOp(params => $params);
    };
    if ($@) {
        my $error = $@;
        $errmsg = "EOperation::EPostStopNode->checkOp failed :\n$error";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    # Instanciate executor Cluster
    $self->{executor}->{obj} = Entity::ServiceProvider::Inside::Cluster->get(
                                   id => $args{internal_cluster}->{executor}
                               );
    $log->debug("Executor Cluster get with ref : " . ref($self->{executor}->{obj}));

    # Instanciate bootserver Cluster
    $self->{bootserver}->{obj} = Entity::ServiceProvider::Inside::Cluster->get(
                                     id => $args{internal_cluster}->{bootserver}
                                 );
    $log->debug("Bootserver Cluster get with ref : " . ref($self->{bootserver}->{obj}));

    # Instanciate context
    $self->loadContext(internal_cluster => $args{internal_cluster}, service => "bootserver");
    $self->loadContext(internal_cluster => $args{internal_cluster}, service => "executor");

    # Instanciate tftpd component
    $self->{_objs}->{component_tftpd}
        = EFactory::newEEntity(
              data => $self->{bootserver}->{obj}->getComponent(name => "Atftpd", version => "0")
          );

    $log->info("Load tftpd component (Atftpd version 0.7, it ref is " . ref($self->{_objs}->{component_tftpd}));

    # Instanciate dhcpd component
    $self->{_objs}->{component_dhcpd}
        = EFactory::newEEntity(
              data => $self->{bootserver}->{obj}->getComponent(name => "Dhcpd", version => "3")
          );

    $log->info("Load dhcp component (Dhcpd version 3, it ref is " . ref($self->{_objs}->{component_tftpd}));

    # Get context for executor
    my $exec_cluster
        = Entity::ServiceProvider::Inside::Cluster->get(id => $args{internal_cluster}->{executor});
    $self->{executor}->{econtext} = EFactory::newEContext(ip_source      => $exec_cluster->getMasterNodeIp(),
                                                          ip_destination => $exec_cluster->getMasterNodeIp());
                                                          
    $self->{kanopya_domainname} = $exec_cluster->getAttr(name => 'cluster_domainname');
}

sub execute {
    my $self = shift;
    $self->SUPER::execute();

    # We stop host (to update powersupply)
    my $ehost = EFactory::newEEntity(data => $self->{_objs}->{host});
    $ehost->stop(econtext => $self->{executor}->{econtext});

    # Remove Host from the dhcp
    my $host_mac = $self->{_objs}->{host}->getPXEIface->getAttr(name => 'iface_mac_addr');
    if ($host_mac) {
        my $subnet = $self->{_objs}->{component_dhcpd}->_getEntity()->getInternalSubNetId();

        my $hostid = $self->{_objs}->{component_dhcpd}->_getEntity()->getHostId(
                         dhcpd3_subnet_id         => $subnet,
                         dhcpd3_hosts_mac_address => $host_mac
                     );

        $self->{_objs}->{component_dhcpd}->removeHost(dhcpd3_subnet_id => $subnet,
                                                      dhcpd3_hosts_id  => $hostid);
        $self->{_objs}->{component_dhcpd}->generate(econtext => $self->{bootserver}->{econtext});
        $self->{_objs}->{component_dhcpd}->reload(econtext => $self->{bootserver}->{econtext});
    }

    # Component migration
    $log->info('Processing cluster components configuration for this node');
    my $components = $self->{_objs}->{components};
    foreach my $i (keys %$components) {
        my $tmp = EFactory::newEEntity(data => $components->{$i});
        $log->debug("component is ".ref($tmp));

        $tmp->removeNode(
            host        => $self->{_objs}->{host},
            cluster     => $self->{_objs}->{cluster},
            mount_point => ''
        );
    }
    
    $self->{_objs}->{host}->setAttr(name => "host_hostname", value => undef);
    $self->{_objs}->{host}->setAttr(name => "host_initiatorname", value => undef);

    
    my $systemimage_name = $self->{_objs}->{cluster}->getAttr(name => 'cluster_name');
    $systemimage_name .= '_' . $self->{_objs}->{host}->getNodeNumber();
    
    # Finally save the host
    $self->{_objs}->{host}->save();

    $self->{_objs}->{host}->stopToBeNode();
    
    # delete the image if persistent policy not set
    if($self->{_objs}->{cluster}->getAttr(name => 'cluster_si_persistent') eq '0') {
        $log->info("cluster image persistence is not set, deleting $systemimage_name");
        eval {
            $self->{_objs}->{systemimage} = Entity::Systemimage->find(
                                                hash => { systemimage_name => $systemimage_name }
                                            );
        };
        if ($@) {
            $log->debug("Could not find systemimage with name <$systemimage_name> for removal.");
        } 
        my $esystemimage = EFactory::newEEntity(data => $self->{_objs}->{systemimage});
        $esystemimage->deactivate(econtext  => $self->{executor}->{econtext},
                                  erollback => $self->{erollback});

        $esystemimage->remove(econtext  => $self->{executor}->{econtext},
                              erollback => $self->{erollback});
    
    } else {
        $log->info("cluster image persistence is set, keeping $systemimage_name image");
    }


    my $ecluster = EFactory::newEEntity(data => $self->{_objs}->{cluster});
    $ecluster->updateHostsFile(
        executor_context   => $self->{executor}->{econtext},
        kanopya_domainname => $self->{kanopya_domainname}
    );
   
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
