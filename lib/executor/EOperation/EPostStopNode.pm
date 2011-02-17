# ERemoveMotherboardFromCluster.pm - Operation class node removing from cluster operation

# Copyright (C) 2009, 2010, 2011, 2012, 2013
#   Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to the
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 14 july 2010

=head1 NAME

EOperation::ERemoveMotherboardFromCluster - Operation class implementing node removing operation

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

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';

=head2 new

EOperation::ERemoveMotherboardFromCluster->new creates a new ERemoveMotherboardFromCluster operation.

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
    
    if($self->{_objs}->{motherboard}->getAttr(name => 'motherboard_state') =~ /^stopping:/) {
		my $msg = "Node is still in stopping state.";
		$log->error($msg);
		throw Mcs::Exception::Execution::OperationReported(error => $msg);
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
		$errmsg = "EAddMotherboardInCluster->prepare need an internal_cluster named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}


	my $params = $self->_getOperation()->getParams();
	
# Instantiate motherboard and so check if exists
    $log->debug("checking motherboard existence with id <$params->{motherboard_id}>");
    eval {
    	$self->{_objs}->{motherboard} = Entity::Motherboard->get(id => $params->{motherboard_id});
    };
    if($@) {
    	$errmsg = "EOperation::EActivateMotherboard->new : motherboard_id $params->{motherboard_id} does not exist";
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
		$errmsg = "Operation ActivateMotherboard failed an error occured :\n$error";
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
	
	
	#### Get Internal IP
	$log->info("Get Internal Cluster IP");
	# Get Internal Ip address of Master node of cluster Executor
	my $exec_ip = $self->{executor}->{obj}->getMasterNodeIp();
	$log->debug("Executor ip is : <$exec_ip>");
	# Get Internal Ip address of Master node of cluster nas
	my $nas_ip = $self->{nas}->{obj}->getMasterNodeIp();
	$log->debug("Nas ip is : <$nas_ip>");
	# Get Internal Ip address of Master node of cluster bootserver
	my $bootserver_ip = $self->{bootserver}->{obj}->getMasterNodeIp();
	$log->debug("Bootserver ip is : <$bootserver_ip>");
	
	
	#### Instanciate context 
	$log->info("Get Internal Cluster context");
	# Get context for nas
	$self->{nas}->{econtext} = EFactory::newEContext(ip_source => $exec_ip, ip_destination => $nas_ip);
	$log->debug("Get econtext for nas with ip ($nas_ip) and ref " . ref($self->{nas}->{econtext}));
	# Get context for bootserver
	$self->{bootserver}->{econtext} = EFactory::newEContext(ip_source => $exec_ip, ip_destination => $bootserver_ip);
	$log->debug("Get econtext for bootserver with ip ($bootserver_ip)" . ref($self->{bootserver}->{econtext}));
	# Get context for executor
	$self->{econtext} = EFactory::newEContext(ip_source => "127.0.0.1", ip_destination => "127.0.0.1");
	$log->debug("Get econtext for executor with ref ". ref($self->{econtext}));
	
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
	
	# We stop motherboard (to update powersupply)
	my $emotherboard = EFactory::newEEntity(data => $self->{_objs}->{motherboard});
	$emotherboard->stop();

    $self->{_objs}->{motherboard}->stopToBeNode(cluster_id => $self->{_objs}->{cluster}->getAttr(name=>"cluster_id"));
    	

    $self->{_objs}->{motherboard}->stopToBeNode(cluster_id => $self->{_objs}->{cluster}->getAttr(name=>"cluster_id"));
	if (!$self->{_objs}->{cluster}->getCurrentNodesCount ()){
       $self->{_objs}->{cluster}->setAttr(name => 'cluster_state', value => 'down');
	   $self->{_objs}->{cluster}->save();
    }
	## Remove Motherboard in the dhcp
	my $subnet = $self->{_objs}->{component_dhcpd}->_getEntity()->getInternalSubNet();
	my $motherboard_mac = $self->{_objs}->{motherboard}->getAttr(name => "motherboard_mac_address");
	my $hostid =$self->{_objs}->{component_dhcpd}->_getEntity()->getHostId(dhcpd3_subnet_id			=> $subnet,
															 			   dhcpd3_hosts_mac_address	=> $motherboard_mac);
	$self->{_objs}->{component_dhcpd}->removeHost(dhcpd3_subnet_id	=> $subnet,
												  dhcpd3_hosts_id	=> $hostid);
	
	$self->{_objs}->{component_dhcpd}->generate(econtext => $self->{bootserver}->{econtext});
	
	$self->{_objs}->{component_dhcpd}->reload(econtext => $self->{bootserver}->{econtext});
	
	# component migration
	my $components = $self->{_objs}->{components};
	$log->info('Processing cluster components configuration for this node');
	foreach my $i (keys %$components) {
		
		my $tmp = EFactory::newEEntity(data => $components->{$i});
		$log->debug("component is ".ref($tmp));
		$tmp->removeNode(motherboard => $self->{_objs}->{motherboard}, 
							mount_point => '',
							cluster => $self->{_objs}->{cluster},
							econtext => $self->{nas}->{econtext});
	}
	


	
	## Remove motherboard etc export from iscsitarget 
	my $node_dev = $self->{_objs}->{motherboard}->getEtcDev();
	my $target_name = $node_dev->{etc}->{lvname};
	my $target_id = $self->{_objs}->{component_export}->_getEntity()->getTargetIdLike(iscsitarget1_target_name => '%'. $target_name);
	my $lun_id =  $self->{_objs}->{component_export}->_getEntity()->getLunId(iscsitarget1_target_id => $target_id,
												iscsitarget1_lun_device => "/dev/$node_dev->{etc}->{vgname}/$node_dev->{etc}->{lvname}");
	
	 
	# we check for existing session on etc target   
	my $tidsid = $self->{_objs}->{component_export}->getIscsiSession(
			targetname => $target_name,	
			initiatorname => $self->{_objs}->{motherboard}->getAttr(name => "motherboard_initiatorname"),
			econtext => $self->{nas}->{econtext}
	);				
	if(defined $tidsid) { 
		$self->{_objs}->{component_export}->cleanIscsiSession(
			tid => $tidsid->{tid},
			sid => $tidsid->{sid},
			econtext => $self->{nas}->{econtext}
		);	
	}
	
	#TODO faire de même pour le nettoyage dela session sur le root systemimage...
	

	$self->{_objs}->{component_export}->removeLun(iscsitarget1_lun_id 	=> $lun_id,
												  iscsitarget1_target_id=>$target_id);
	$self->{_objs}->{component_export}->removeTarget(iscsitarget1_target_id		=>$target_id,
													 iscsitarget1_target_name 	=> $target_name,
													 econtext 					=> $self->{nas}->{econtext});
																  
	$self->{_objs}->{component_export}->generate(econtext => $self->{nas}->{econtext});
	
	$self->{_objs}->{motherboard}->setAttr(name => "motherboard_hostname", value => undef);
	$self->{_objs}->{motherboard}->setAttr(name => "motherboard_initiatorname", value => undef);
	## Update Motherboard internal ip
	$self->{_objs}->{motherboard}->setAttr(name => "motherboard_internal_ip", value => undef);
	
	## finaly save motherboard 
	$self->{_objs}->{motherboard}->save();


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
