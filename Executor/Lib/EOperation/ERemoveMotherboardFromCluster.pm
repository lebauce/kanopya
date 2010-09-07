# ERemoveMotherboardFromCluster.pm - Operation class implementing Cluster creation operation

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

EEntity::Operation::EAddMotherboard - Operation class implementing Motherboard creation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement Motherboard creation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::ERemoveMotherboardFromCluster;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use Data::Dumper;
use vars qw(@ISA $VERSION);
use base "EOperation";
use lib qw (/workspace/mcs/Executor/Lib /workspace/mcs/Common/Lib);
use McsExceptions;
use EFactory;

my $log = get_logger("executor");
my $errmsg;
$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head2 new

    my $op = EEntity::EOperation::EAddMotherboard->new();

EEntity::Operation::EAddMotherboard->new creates a new AddMotheboard operation.

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

	return;
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

	my $adm = Administrator->new();
	my $params = $self->_getOperation()->getParams();

	#### Instanciate Clusters
	$log->info("Get Internal Clusters");
	# Instanciate nas Cluster 
	$self->{nas}->{obj} = $adm->getEntity(type => "Cluster", id => $args{internal_cluster}->{nas});
	$log->debug("Nas Cluster get with ref : " . ref($self->{nas}->{obj}));
	# Instanciate executor Cluster
	$self->{executor}->{obj} = $adm->getEntity(type => "Cluster", id => $args{internal_cluster}->{executor});
	$log->debug("Executor Cluster get with ref : " . ref($self->{executor}->{obj}));
	# Instanciate bootserver Cluster
	$self->{bootserver}->{obj} = $adm->getEntity(type => "Cluster", id => $args{internal_cluster}->{bootserver});
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

	# Get instance of Motherboard Entity
	$log->info("Load Motherboard instance");
	$self->{_objs}->{motherboard} = $adm->getEntity(type => "Motherboard", id => $params->{motherboard_id});
	$log->debug("get Motherboard self->{_objs}->{motherboard} of type : " . ref($self->{_objs}->{motherboard}));

	my $cluster_id = $self->{_objs}->{motherboard}->getClusterId();
	#### Get instance of Cluster Entity
	$log->info("Load cluster instance");
	$self->{_objs}->{cluster} = $adm->getEntity(type => "Cluster", id => $cluster_id);
	$log->debug("get cluster self->{_objs}->{cluster} of type : " . ref($self->{_objs}->{cluster}));

	#### Get cluster components Entities
	$log->info("Load cluster component instances");
	$self->{_objs}->{components}= $self->{_objs}->{cluster}->getComponents(administrator => $adm, category => "all");
	$log->debug("Load all component from cluster");
	
	## Instanciate Component needed (here LVM, ISCSITARGET, DHCP and TFTPD on nas and bootserver cluster)
	# Instanciate Storage component.
	my $tmp = $self->{nas}->{obj}->getComponent(name=>"Lvm",
										 version => "2",
										 administrator => $adm);
	$self->{_objs}->{component_storage} = EFactory::newEEntity(data => $tmp);
	$log->info("Load Lvm component version 2, it ref is " . ref($self->{_objs}->{component_storage}));
	# Instanciate Export component.
	$self->{_objs}->{component_export} = EFactory::newEEntity(data => $self->{nas}->{obj}->getComponent(name=>"Iscsitarget",
																					  version=> "1",
																					  administrator => $adm));
	$log->info("Load export component (iscsitarget version 1, it ref is " . ref($self->{_objs}->{component_export}));
	# Instanciate tftpd component.
	$self->{_objs}->{component_tftpd} = EFactory::newEEntity(data => $self->{bootserver}->{obj}->getComponent(name=>"Atftpd",
																					  version=> "0",
																					  administrator => $adm));
																					  
	$log->info("Load tftpd component (Atftpd version 0.7, it ref is " . ref($self->{_objs}->{component_tftpd}));
	# instanciate dhcpd component.
	$self->{_objs}->{component_dhcpd} = EFactory::newEEntity(data => $self->{bootserver}->{obj}->getComponent(name=>"Dhcpd",
																					  version=> "3",
																					  administrator => $adm));
																					  
	$log->info("Load dhcp component (Dhcpd version 3, it ref is " . ref($self->{_objs}->{component_tftpd}));

}

sub execute{
	my $self = shift;
	$log->debug("Before EOperation exec");
	$self->SUPER::execute();
	$log->debug("After EOperation exec and before new Adm");
	my $adm = Administrator->new();
	
	# first we halt the node
	$self->stopNode();
	
	my $node_dev = $self->{_objs}->{motherboard}->getEtcDev();
	
	my $target_name = $node_dev->{etc}->{lvname};
	my $target_id = $self->{_objs}->{component_export}->_getEntity()->getTargetIdLike(iscsitarget1_target_name => '%'. $target_name);

	my $lun_id =  $self->{_objs}->{component_export}->_getEntity()->getLunId(iscsitarget1_target_id => $target_id,
												iscsitarget1_lun_device => "/dev/$node_dev->{etc}->{vgname}/$node_dev->{etc}->{lvname}");

	$self->{_objs}->{component_export}->removeLun(iscsitarget1_lun_id 	=> $lun_id,
												  iscsitarget1_target_id=>$target_id);
	$self->{_objs}->{component_export}->removeTarget(iscsitarget1_target_id		=>$target_id,
													 iscsitarget1_target_name 	=> $target_name,
													 econtext 					=> $self->{nas}->{econtext});
																  
	$self->{_objs}->{component_export}->reload();
	
	## Remove Motherboard in the dhcp
	my $subnet = $self->{_objs}->{component_dhcpd}->_getEntity()->getInternalSubNet();
	my $motherboard_mac = $self->{_objs}->{motherboard}->getAttr(name => "motherboard_mac_address");
	my $hostid =$self->{_objs}->{component_dhcpd}->_getEntity()->getHostId(dhcpd3_subnet_id			=> $subnet,
															 			   dhcpd3_hosts_mac_address	=> $motherboard_mac);
	$self->{_objs}->{component_dhcpd}->removeHost(dhcpd3_subnet_id	=> $subnet,
												  dhcpd3_hosts_id	=> $hostid);
	
	$self->{_objs}->{component_dhcpd}->generate(econtext => $self->{bootserver}->{econtext});
	
	$self->{_objs}->{component_dhcpd}->reload(econtext => $self->{bootserver}->{econtext});
	
	#Update Motherboard internal ip
	$self->{_objs}->{motherboard}->setAttr(name => "motherboard_internal_ip", value => undef);

	$adm->removeNode(motherboard_id => $self->{_objs}->{motherboard}->getAttr(name=>"motherboard_id"),
					 cluster_id => $self->{_objs}->{cluster}->getAttr(name=>"cluster_id"));
}


sub stopNode {
	my $self = shift;
	my $motherboard_econtext = EFactory::newEContext(
		ip_source => "127.0.0.1", 
		ip_destination => $self->{_objs}->{motherboard}->getAttr(name => 'motherboard_internal_ip')
	);
	my $command = 'halt';
	my $result = $motherboard_econtext->execute(command => $command);
	my $state = 'stopping:'.time;
	$self->{_objs}->{motherboard}->setAttr(name => 'motherboard_state', value => $state);
	$self->{_objs}->{motherboard}->save();
}


__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut