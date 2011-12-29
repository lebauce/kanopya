# EPostStopNode.pm - Operation class node removing from cluster operation

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
use Entity::Cluster;
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
    RELATIVE => 1,                   # desactive par defaut
};
=head2 new

EOperation::EPostStopNode->new creates a new EPostStopNode operation.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    $log->debug("Class is : $class");
    my $self = $class->SUPER::new(%args);
    $self->_init();
    
    return $self;
}

=head2 _init

    $op->_init() is a private method used to define internal parameters.

=cut

sub _init {
    my $self = shift;
    $self->{duration_report} = 60; # specific duration for operation reporting (in seconds)
    return;
}

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

    if (! exists $args{internal_cluster} or ! defined $args{internal_cluster}) { 
        $errmsg = "EPostStopNode->prepare need an internal_cluster named argument!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }


    my $params = $self->_getOperation()->getParams();
    
# Instantiate host and so check if exists
    $log->debug("checking host existence with id <$params->{host_id}>");
    eval {
        $self->{_objs}->{host} = Entity::Host->get(id => $params->{host_id});
    };
    if($@) {
        $errmsg = "EOperation::EActivateHost->new : host_id $params->{host_id} does not exist";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
     # Cluster instantiation
    $log->debug("checking cluster existence with id <$params->{cluster_id}>");
    eval {
        $self->{_objs}->{cluster} = Entity::Cluster->get(id => $params->{cluster_id});
    };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::EActivateCluster->prepare : cluster_id $params->{cluster_id} does not find\n" . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    #### Get cluster components Entities
    $log->info("Load cluster component instances");
    $self->{_objs}->{components}= $self->{_objs}->{cluster}->getComponents(category => "all");
    $log->debug("Load all component from cluster");
    
    eval {
        $self->checkOp(params => $params);
    };
    if ($@) {
        my $error = $@;
        $errmsg = "Operation ActivateHost failed an error occured :\n$error";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
        
    #### Instanciate Clusters
    $log->info("Get Internal Clusters");
    # Instanciate nas Cluster 
    $self->{nas}->{obj} = Entity::Cluster->get(id => $args{internal_cluster}->{nas});
    $log->debug("Nas Cluster get with ref : " . ref($self->{nas}->{obj}));
    # Instanciate executor Cluster
    $self->{executor}->{obj} = Entity::Cluster->get(id => $args{internal_cluster}->{executor});
    $log->debug("Executor Cluster get with ref : " . ref($self->{executor}->{obj}));
    # Instanciate bootserver Cluster
    $self->{bootserver}->{obj} = Entity::Cluster->get(id => $args{internal_cluster}->{bootserver});
    $log->debug("Bootserver Cluster get with ref : " . ref($self->{bootserver}->{obj}));
    
    
    #### Instanciate context 
    $self->loadContext(internal_cluster => $args{internal_cluster}, service => "nas");
    $self->loadContext(internal_cluster => $args{internal_cluster}, service => "bootserver");
    $self->loadContext(internal_cluster => $args{internal_cluster}, service => "executor");
    
    ## Instanciate Component needed (here LVM, ISCSITARGET, DHCP and TFTPD on nas and bootserver cluster)
    # Instanciate Storage component.
    my $tmp = $self->{nas}->{obj}->getComponent(name=>"Lvm",
                                         version => "2");
    $self->{_objs}->{component_storage} = EFactory::newEEntity(data => $tmp);
    $log->info("Load Lvm component version 2, it ref is " . ref($self->{_objs}->{component_storage}));
    # Instanciate Export component.
    $self->{_objs}->{component_export} = EFactory::newEEntity(data => $self->{nas}->{obj}->getComponent(name=>"Iscsitarget",
                                                                                      version=> "1"));
    $log->info("Load export component (iscsitarget version 1, it ref is " . ref($self->{_objs}->{component_export}));
    # Instanciate tftpd component.
    $self->{_objs}->{component_tftpd} = EFactory::newEEntity(data => $self->{bootserver}->{obj}->getComponent(name=>"Atftpd",
                                                                                      version=> "0"));
                                                                                      
    $log->info("Load tftpd component (Atftpd version 0.7, it ref is " . ref($self->{_objs}->{component_tftpd}));
    # instanciate dhcpd component.
    $self->{_objs}->{component_dhcpd} = EFactory::newEEntity(data => $self->{bootserver}->{obj}->getComponent(name=>"Dhcpd",
                                                                                      version=> "3"));
                                                                                      
    $log->info("Load dhcp component (Dhcpd version 3, it ref is " . ref($self->{_objs}->{component_tftpd}));

}

sub execute {
    my $self = shift;
    $log->debug("Before EOperation exec");
    $self->SUPER::execute();
    $log->debug("After EOperation exec and before new Adm");
    my $adm = Administrator->new();
    
    # We stop host (to update powersupply)
    my $ehost = EFactory::newEEntity(data => $self->{_objs}->{host});
    $ehost->stop();

     $self->{_objs}->{host}->stopToBeNode(cluster_id => $self->{_objs}->{cluster}->getAttr(name=>"cluster_id"));

    ## Remove Host in the dhcp
    my $subnet = $self->{_objs}->{component_dhcpd}->_getEntity()->getInternalSubNetId();
    my $host_mac = $self->{_objs}->{host}->getAttr(name => "host_mac_address");
    my $hostid =$self->{_objs}->{component_dhcpd}->_getEntity()->getHostId(dhcpd3_subnet_id            => $subnet,
                                                                            dhcpd3_hosts_mac_address    => $host_mac);
    $self->{_objs}->{component_dhcpd}->removeHost(dhcpd3_subnet_id    => $subnet,
                                                  dhcpd3_hosts_id    => $hostid);
    ########## Strange : $self->{_objs}->{host}->removeInternalIP();
    $self->{_objs}->{component_dhcpd}->generate(econtext => $self->{bootserver}->{econtext});
    
    $self->{_objs}->{component_dhcpd}->reload(econtext => $self->{bootserver}->{econtext});
    
    # component migration
    my $components = $self->{_objs}->{components};
    $log->info('Processing cluster components configuration for this node');
    foreach my $i (keys %$components) {
        
        my $tmp = EFactory::newEEntity(data => $components->{$i});
        $log->debug("component is ".ref($tmp));
        $tmp->removeNode(host => $self->{_objs}->{host}, 
                            mount_point => '',
                            cluster => $self->{_objs}->{cluster},
                            econtext => $self->{nas}->{econtext});
    }
    


    
    ## Remove host etc export from iscsitarget 
    my $node_dev = $self->{_objs}->{host}->getEtcDev();
    my $lv_name = $node_dev->{etc}->{lvname};
    my $target_name = $self->{_objs}->{component_export}->_getEntity()->getFullTargetName(lv_name => $lv_name);
    my $target_id = $self->{_objs}->{component_export}->_getEntity()->getTargetIdLike(iscsitarget1_target_name => '%'. $lv_name);
    my $lun_id =  $self->{_objs}->{component_export}->_getEntity()->getLunId(iscsitarget1_target_id => $target_id,
                                                iscsitarget1_lun_device => "/dev/$node_dev->{etc}->{vgname}/$node_dev->{etc}->{lvname}");
    
    # clean initiator session 
    $self->{_objs}->{component_export}->cleanInitiatorSession(
        econtext => $self->{nas}->{econtext},
        initiator => $self->{_objs}->{host}->getAttr(name => 'host_initiatorname'), 
    );
    
    
    $self->{_objs}->{component_export}->removeLun(iscsitarget1_lun_id     => $lun_id,
                                                  iscsitarget1_target_id=>$target_id);
    $self->{_objs}->{component_export}->removeTarget(iscsitarget1_target_id        =>$target_id,
                                                     iscsitarget1_target_name     => $target_name,
                                                     econtext                     => $self->{nas}->{econtext});
                                                                  
    $self->{_objs}->{component_export}->generate(econtext => $self->{nas}->{econtext});
    
    $self->{_objs}->{host}->setAttr(name => "host_hostname", value => undef);
    $self->{_objs}->{host}->setAttr(name => "host_initiatorname", value => undef);
    ## Update Host internal ip
    $self->{_objs}->{host}->removeInternalIP();
    
    ## finaly save host 
    $self->{_objs}->{host}->save();
    ## update of etc/hosts
   my $nodes = $self->{_objs}->{cluster}->getHosts();
   $log->info("Generate Hosts Conf");
    my $etc_hosts_file = $self->generateHosts(nodes => $nodes);
    foreach my $i (keys %$nodes) 
    {
	    my $node = $nodes->{$i};
        my $node_econtext = EFactory::newEContext(ip_source => "127.0.0.1", ip_destination => $nodes->{$i}->getInternalIP()->{ipv4_internal_address});
        $node_econtext->send(src => $etc_hosts_file, dest => "/etc/hosts");
    }    


}
sub generateHosts {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args);

    my $rand = new String::Random;
    my $tmpfile = $rand->randpattern("cccccccc");

    # create Template object
    my $template = Template->new($config);
    my $input = "hosts.tt";
    my $nodes = $args{nodes};
    my @nodes_list = ();
    
    foreach my $i (keys %$nodes) {
        my $tmp = {hostname     => $nodes->{$i}->getAttr(name => 'host_hostname'),
                   domainname   => "hedera-technology.com",
                   ip           => $nodes->{$i}->getInternalIP()->{ipv4_internal_address}};
        push @nodes_list, $tmp;
    }
    my $vars = {hostname    => $self->{_objs}->{host}->getAttr(
		        name        => "host_hostname"),
	            domainname  => "hedera-technology.com",
                hosts       => \@nodes_list,
               };
    $log->debug(Dumper($vars));
    $template->process($input, $vars, "/tmp/$tmpfile") || die $template->error(), "\n";
   return("/tmp/".$tmpfile);
   # $self->{nas}->{econtext}->send(src => "/tmp/".$tmpfile, dest => "/etc/hosts");
   # unlink     "/tmp/$tmpfile";
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

Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

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
