# EStartNode.pm - Operation class implementing Cluster creation operation

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

EEntity::Operation::EStartNode - Operation class implementing Motherboard creation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement Motherboard creation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EStartNode;
use base "EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use String::Random;
use Date::Simple (':all');

use Kanopya::Exceptions;
use EFactory;
use Entity::Cluster;
use Entity::Motherboard;
use Template;

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

    my $op = EOperation::EStartNode->new();

	# Operation::EStartNode->new creates a new AddMotheboardInCluster operation.
	# RETURN : EOperation::EStartNode : Operation add motherboard in a cluster

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    my $self = $class->SUPER::new(%args);
    $self->_init();
    
    return $self;
}

=head2 _init

	$op->_init();
	# This private method is used to define some hash in Operation

=cut

sub _init {
	my $self = shift;
	$self->{nas} = {};
	$self->{executor} = {};
	$self->{bootserver} = {};
	$self->{monitor} = {};
	$self->{_objs} = {};
	return;
}

=head2 prepare

	$op->prepare(internal_cluster => \%internal_clust);

=cut

sub prepare {
	
	my $self = shift;
	my %args = @_;
	$self->SUPER::prepare();

	$log->info("Operation preparation");

	if (! exists $args{internal_cluster} or ! defined $args{internal_cluster}) { 
		$errmsg = "EStartNode->prepare need an internal_cluster named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}

	my $params = $self->_getOperation()->getParams();

 	# Cluster instantiation
    $log->debug("checking cluster existence with id <$params->{cluster_id}>");
    eval {
    	$self->{_objs}->{cluster} = Entity::Cluster->get(id => $params->{cluster_id});
    };
    if($@) {
        my $err = $@;
    	$errmsg = "EOperation::EStartNode->prepare : cluster_id $params->{cluster_id} does not find\n" . $err;
    	$log->error($errmsg);
    	throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

 	# Motherboard instantiation
    $log->debug("checking Motherboard existence with id <$params->{motherboard_id}>");
    eval {
    	$self->{_objs}->{motherboard} = Entity::Motherboard->get(id => $params->{motherboard_id});
    };
    if($@) {
        my $err = $@;
    	$errmsg = "EOperation::EStartNode->prepare : motherboard_id $params->{motherboard_id} does not find\n" . $err;
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
	# Instanciate monitor Cluster
	$self->{monitor}->{obj} = Entity::Cluster->get(id => $args{internal_cluster}->{monitor});
	$log->debug("Monitor Cluster get with ref : " . ref($self->{monitor}->{obj}));
	
	
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
	# Get Internal Ip address of Master node of cluster monitor
	my $monitor_ip = $self->{monitor}->{obj}->getMasterNodeIp();
	$log->debug("Monitor ip is : <$monitor_ip>");
	
	
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

	#### Get cluster components Entities
	$log->info("Load cluster component instances");
	$self->{_objs}->{components}= $self->{_objs}->{cluster}->getComponents(category => "all");
	$log->debug("Load all component from cluster");
	
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
	
	## Clone system image etc on motherboard etc
	# Get system image etc
	my $sysimg_dev = $self->{_objs}->{cluster}->getSystemImage()->getDevices();
	my $node_dev = $self->{_objs}->{motherboard}->getEtcDev();
	# copy of systemimage etc source to motherboard etc device
	$log->info('Cloning system image etc device to the new node');
	my $command = "dd if=/dev/$sysimg_dev->{etc}->{vgname}/$sysimg_dev->{etc}->{lvname} of=/dev/$node_dev->{etc}->{vgname}/$node_dev->{etc}->{lvname} bs=1M";
	my $result = $self->{nas}->{econtext}->execute(command => $command);
	
	## Update export to allow to motherboard to boot
	#TODO Update export root and mount_point to add motherboard as allowed to access to this disk
	my $target_name = $self->{_objs}->{component_export}->generateTargetname(name => $self->{_objs}->{motherboard}->getEtcName());

	# Get etc iscsi target information
	my $node_etc_export ={iscsitarget1_target_name=>$target_name,
					 mountpoint=>"/etc",
					 mount_option=>""};
	$node_etc_export->{econtext} = $self->{nas}->{econtext};
	my $target_id = $self->{_objs}->{component_export}->addTarget(%$node_etc_export);
	delete $node_etc_export->{econtext};															  
	$self->{_objs}->{component_export}->addLun(iscsitarget1_target_id	=> $target_id,
												iscsitarget1_lun_number	=> 0,
												iscsitarget1_lun_device	=> "/dev/$node_dev->{etc}->{vgname}/$node_dev->{etc}->{lvname}",
												iscsitarget1_lun_typeio	=> "fileio",
												iscsitarget1_lun_iomode	=> "wb",
												iscsitarget1_target_name=>$target_name,
												econtext 				=> $self->{nas}->{econtext});
	
	# 
	$self->{_objs}->{component_export}->generate(econtext => $self->{nas}->{econtext});
		
	## ADD Motherboard in the dhcp
	my $subnet = $self->{_objs}->{component_dhcpd}->_getEntity()->getInternalSubNetId();
	my $motherboard_ip = $adm->{manager}->{network}->getFreeInternalIP();
	# Set Hostname
	$self->{_objs}->{motherboard}->setAttr(name => "motherboard_hostname",
										   value => $self->{_objs}->{motherboard}->generateHostname(ip=>$motherboard_ip));
	# Set initiatorName
	$self->{_objs}->{motherboard}->setAttr(name => "motherboard_initiatorname",
										   value => $self->{_objs}->{component_export}->generateInitiatorname(hostname => $self->{_objs}->{motherboard}->getAttr(name=>'motherboard_hostname')));
	
	# Configure DHCP Component
	my $motherboard_mac = $self->{_objs}->{motherboard}->getAttr(name => "motherboard_mac_address");
	my $motherboard_hostname = $self->{_objs}->{motherboard}->getAttr(name => "motherboard_hostname");
	my $motherboard_kernel_id;# = $self->{_objs}->{motherboard}->getAttr(name => "kernel_id");
	my $tmp_kernel_id = $self->{_objs}->{cluster}->getAttr(name => "kernel_id");
	if ($tmp_kernel_id) {
	    $motherboard_kernel_id = $tmp_kernel_id;
	} else {
	    $motherboard_kernel_id = $self->{_objs}->{motherboard}->getAttr(name => "kernel_id");
	}

	$self->{_objs}->{component_dhcpd}->addHost( dhcpd3_subnet_id		=> $subnet,
												dhcpd3_hosts_ipaddr	=> $motherboard_ip,
												dhcpd3_hosts_mac_address	=> $motherboard_mac,
												dhcpd3_hosts_hostname	=> $motherboard_hostname,
												dhcpd3_hosts_ntp_server => $self->{bootserver}->{obj}->getMasterNodeIp(),
												dhcpd3_hosts_domain_name =>$self->{_objs}->{cluster}->getAttr(name => "cluster_domainname"),
												dhcpd3_hosts_domain_name_server => $self->{_objs}->{cluster}->getAttr(name => "cluster_nameserver"),
												kernel_id	=> $motherboard_kernel_id);
	
	$log->info('generate dhcp configuration file');
	$self->{_objs}->{component_dhcpd}->generate(econtext => $self->{bootserver}->{econtext});
	$log->info('restart dhcp service');
	$self->{_objs}->{component_dhcpd}->reload(econtext => $self->{bootserver}->{econtext});
	
	#Update Motherboard internal ip
	$self->{_objs}->{motherboard}->setAttr(name => "motherboard_internal_ip", value => $motherboard_ip);
	#TODO Manage gateway in motherboard with cluster ???
	my %subnet_hash = $self->{_objs}->{component_dhcpd}->_getEntity()->getSubNet(dhcp3_subnet_id => $subnet);

    my $ipv4_internal_id = $self->{_objs}->{motherboard}->setInternalIP(ipv4_internal_address => $motherboard_ip,
                                                 ipv4_internal_mask => $subnet_hash{'dhcpd3_subnet_mask'});
    #$self->{_objs}->{motherboard}->setAttr(name => "motherboard_ipv4_internal_id", value => $ipv4_internal_id);
	# Mount Motherboard etc to populate it
	my $mkdir_cmd = "mkdir -p /mnt/$node_dev->{etc}->{lvname}";
	$self->{nas}->{econtext}->execute(command => $mkdir_cmd);
	my $mount_cmd = "mount /dev/$node_dev->{etc}->{vgname}/$node_dev->{etc}->{lvname} /mnt/$node_dev->{etc}->{lvname}";
	$self->{nas}->{econtext}->execute(command => $mount_cmd);

	my $clust_nodes = $self->{_objs}->{cluster}->getMotherboards();	
	# Generate Node configuration
	$self->_generateNodeConf(mount_point => "/mnt/$node_dev->{etc}->{lvname}",
					 		root_dev 	=> $sysimg_dev->{root},
					 		etc_dev		=> $node_dev->{etc},
					 		etc_export	=> $node_etc_export,
					 		nodes		=> $clust_nodes);
	

	
	#TODO  component migrate (node, exec context?)
	my $components = $self->{_objs}->{components};
	$log->info('Processing cluster components configuration for this node');
	foreach my $i (keys %$components) {
		my $tmp = EFactory::newEEntity(data => $components->{$i});
		$log->debug("component is ".ref($tmp));
		$tmp->addNode(motherboard => $self->{_objs}->{motherboard}, 
							mount_point => "/mnt/$node_dev->{etc}->{lvname}",
							cluster => $self->{_objs}->{cluster},
							econtext => $self->{nas}->{econtext});
	}

	# Umount Motherboard etc to populate it
	my $umount_cmd = "umount /mnt/$node_dev->{etc}->{lvname}";
	$self->{nas}->{econtext}->execute(command => $umount_cmd);
	my $rmdir_cmd = "rmdir /mnt/$node_dev->{etc}->{lvname}";
	$self->{nas}->{econtext}->execute(command => $rmdir_cmd);

	# Create node instance
#	$self->{_objs}->{motherboard}->becomeNode(cluster_id => $self->{_objs}->{cluster}->getAttr(name=>"cluster_id"),
#                          					  master_node => $masternode);
    $self->{_objs}->{motherboard}->setNodeState(state=>"goingin");
	$self->{_objs}->{motherboard}->save();
	
	# finaly we start the node
	my $emotherboard = EFactory::newEEntity(data => $self->{_objs}->{motherboard});
	$emotherboard->start(econtext =>$self->{econtext});
}

sub _generateNodeConf {
	my $self = shift;
	my %args = @_;

	if ((! exists $args{mount_point} or ! defined $args{mount_point}) ||
		(! exists $args{root_dev} or ! defined $args{root_dev}) ||
		(! exists $args{etc_dev} or ! defined $args{etc_dev}) ||
		(! exists $args{etc_export} or ! defined $args{etc_export})||
		(! exists $args{nodes} or ! defined $args{nodes})) { 
		$errmsg = "EOperation::EStartNode->generateNodeConf need a mount_point named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $initiatorname = $self->{_objs}->{motherboard}->getAttr(name => "motherboard_initiatorname");
	$log->info("Generate Initiator Conf");
	$self->_generateInitiatorConf(initiatorname => $initiatorname, mount_point=>$args{mount_point});
	$log->info("Generate Udev Conf");
	$self->_generateUdevConf(mount_point=>$args{mount_point});
	$log->info("Generate Fstab Conf");
	$self->_generateFstabConf(mount_point=>$args{mount_point}, root_dev => $args{root_dev}, etc_dev => $args{etc_dev});
	$log->info("Generate Kanopya Halt script Conf");
	$self->_generateKanopyaHalt(mount_point=>$args{mount_point}, etc_export => $args{etc_export});
#	$log->info("Generate Hosts Conf");
#	$self->generateHosts(mount_point=>$args{mount_point}, nodes => $args{nodes});
	$log->info("Generate Network Conf");
	$self->_generateNetConf(mount_point=>$args{mount_point});
	$log->info("Generate resolv.conf");
	$self->_generateResolvConf(mount_point=>$args{mount_point});
#TODO generateRouteConf
	$log->info("Generate Boot Conf");
	$self->_generateBootConf(mount_point=>$args{mount_point},
							initiatorname => $initiatorname,
							root_dev => $args{root_dev},
							etc_dev => $args{etc_dev},
							etc_export => $args{etc_export});	
}

sub _generateInitiatorConf {
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{mount_point} or ! defined $args{mount_point}) ||
		(! exists $args{initiatorname} or ! defined $args{initiatorname})) { 
		$errmsg = "EOperation::EStartNode->generateInitiatorConf need a mount_point and an initiatorname named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	$self->{nas}->{econtext}->execute(command=>"echo \"InitiatorName=$args{initiatorname}\" > $args{mount_point}/iscsi/initiatorname.iscsi");
}

sub _generateUdevConf{
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{mount_point} or ! defined $args{mount_point})) { 
		$errmsg = "EOperation::EStartNode->generateUdevConf need a mount_point named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $rand = new String::Random;
	my $tmpfile = $rand->randpattern("cccccccc");
	# create Template object
	my $template = Template->new($config);
    my $input = "udev_70-persistent-net.rules.tt";
	
	#TODO Get ALL network interface !
	my $interfaces = [{mac_address => lc($self->{_objs}->{motherboard}->getAttr(name => "motherboard_mac_address")), net_interface => "eth0"}];
	$log->debug(Dumper($interfaces));
	$template->process($input, {interfaces => $interfaces}, "/tmp/".$tmpfile) || die $template->error(), "\n";
    $self->{nas}->{econtext}->send(src => "/tmp/$tmpfile", dest => "$args{mount_point}/udev/rules.d/70-persistent-net.rules");	
	unlink "/tmp/$tmpfile";
}

sub _generateFstabConf{
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{mount_point} or ! defined $args{mount_point})||
		(! exists $args{root_dev} or ! defined $args{root_dev})||
		(! exists $args{etc_dev} or ! defined $args{etc_dev})){
		$errmsg = "EOperation::EStartNode->generateFstabConf need a mount_point, a root_dev and etc_dev named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $rand = new String::Random;
	my $template = Template->new($config);
	my $tmpfile = $rand->randpattern("cccccccc");
	my $input = "fstab.tt";
	
	$log->debug("Get targetid with the following pattern : " . '%'."$args{root_dev}->{lvname}");
	my $root_target_id = $self->{_objs}->{component_export}->_getEntity()->getTargetIdLike(iscsitarget1_target_name => '%'."$args{root_dev}->{lvname}");
	my $root_target = $self->{_objs}->{component_export}->_getEntity()->getTarget(iscsitarget1_target_id => $root_target_id);
	$log->debug("Get targetid with the following pattern : " . '%'."$args{etc_dev}->{lvname}");
	my $etc_target_id = $self->{_objs}->{component_export}->_getEntity()->getTargetIdLike(iscsitarget1_target_name => '%'."$args{etc_dev}->{lvname}");
	my $etc_target = $self->{_objs}->{component_export}->_getEntity()->getTarget(iscsitarget1_target_id => $etc_target_id);
	my $nas_ip = $self->{nas}->{obj}->getMasterNodeIp();
	my $vars = {#etc_dev			=> "/dev/sdb",
   	    		etc_dev			=> "/dev/disk/by-path/ip-".$nas_ip.":3260-iscsi-".$etc_target->{target}."-lun-0",
   	    		etc_fs			=> $args{etc_dev}->{filesystem},
				etc_options		=> "defaults",
				#root_dev		=> "/dev/sda",
				root_dev		=> "/dev/disk/by-path/ip-".$nas_ip.":3260-iscsi-".$root_target->{target}."-lun-0",
				root_fs			=> $args{root_dev}->{filesystem},
				root_options	=> "ro,noatime,nodiratime",
				
   	   };
   	   
   	my $components = $self->{_objs}->{components};
   	$vars->{mounts_iscsi} = [];
	foreach my $i (keys %$components) {
		my $tmp = $components->{$i};
		$log->debug("Found component of type : " . ref($tmp));
		if ($components->{$i}->isa("Entity::Component::Exportclient")) {
			$log->debug("The cluster component is an Exportclient");
			#TODO Check if it is an ExportClient and call generic method/
			if ($components->{$i}->isa("Entity::Component::Exportclient::Openiscsi2")){
				$log->debug("The cluster component is an Openiscsi2");
				my $iscsi_export = $components->{$i};
				$vars->{mounts_iscsi} = $iscsi_export->getExports();
   			}
		}
	}
	$log->debug(Dumper($vars));
   	$template->process($input, $vars, "/tmp/".$tmpfile) || die $template->error(), "\n";
    $self->{nas}->{econtext}->send(src => "/tmp/$tmpfile", dest => "$args{mount_point}/fstab");	
	unlink "/tmp/$tmpfile";
}

sub _generateKanopyaHalt{
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{mount_point} or ! defined $args{mount_point})||
		(! exists $args{etc_export} or ! defined $args{etc_export})){
		$errmsg = "EOperation::EStartNode->generateKanopyaHalt need a mount_point, a root_dev and etc_dev named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $rand = new String::Random;
	my $template = Template->new($config);
	my $tmpfile = $rand->randpattern("cccccccc");
	my $tmpfile2 = $rand->randpattern("cccccccc");
	my $input = "KanopyaHalt.tt";
	my $omitted_file = "Kanopya_omitted_iscsid";
	#TODO mettre en parametre le port du iscsi du nas!!
	my $vars = {etc_target		=> $args{etc_export}->{iscsitarget1_target_name},
   	    		nas_ip			=> $self->{nas}->{obj}->getMasterNodeIp(),
				nas_port		=> "3260",
   	   };
   	my $components = $self->{_objs}->{components};
   	foreach my $i (keys %$components) {
		my $tmp = $components->{$i};
        #TODO Check if it is an ExportClient and call generic method/
		if ($components->{$i}->isa("Entity::Component::Exportclient")) {
			if ($components->{$i}->isa("Entity::Component::Exportclient::Openiscsi2")){
				$log->debug("The cluster component is an Openiscsi2");
				my $iscsi_export = $components->{$i};
				$vars->{data_exports} = $iscsi_export->getExports();
   			}
		}
	}
   	$log->debug(Dumper($vars));
   	$template->process($input, $vars, "/tmp/".$tmpfile) || die $template->error(), "\n";
    $self->{nas}->{econtext}->send(src => "/tmp/$tmpfile", dest => "$args{mount_point}/init.d/Kanopya_halt");
    unlink "/tmp/$tmpfile";
    $self->{nas}->{econtext}->execute(command=> "chmod 755 $args{mount_point}/init.d/Kanopya_halt");
    $self->{nas}->{econtext}->execute(command=> "ln -sf ../init.d/Kanopya_halt $args{mount_point}/rc0.d/S89Kanopya_halt");
	
	$self->{nas}->{econtext}->execute(command=> "cp /templates/internal/$omitted_file /tmp/");
   	$self->{nas}->{econtext}->send(src => "/tmp/$omitted_file", dest => "$args{mount_point}/init.d/Kanopya_omitted_iscsid");
   	unlink "/tmp/$omitted_file";
   	$self->{nas}->{econtext}->execute(command=> "chmod 755 $args{mount_point}/init.d/Kanopya_omitted_iscsid");
   	$self->{nas}->{econtext}->execute(command=> "ln -sf ../init.d/Kanopya_omitted_iscsid $args{mount_point}/rc0.d/S19Kanopya_omitted_iscsid");
}

sub _generateHosts {
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{mount_point} or ! defined $args{mount_point}) ||
		(! exists $args{nodes} or ! defined $args{nodes})) { 
		$errmsg = "EOperation::EStartNode->generateHosts need a mount_point and nodes named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $rand = new String::Random;
	my $tmpfile = $rand->randpattern("cccccccc");

	# create Template object
	my $template = Template->new($config);
    my $input = "hosts.tt";
    my $nodes = $args{nodes};
    my @nodes_list = ();
    my $vars = {hostname		=> $self->{_objs}->{motherboard}->getAttr(name => "motherboard_hostname"),
   	    		domainname			=> "hedera-technology.com",
				hosts		=> \@nodes_list,
   	   };
	foreach my $i (keys %$nodes) {
		my $tmp = {hostname 	=> $nodes->{$i}->getAttr(name => 'motherboard_hostname'),
				   domainname	=> "hedera-technology.com",
				   ip			=> $nodes->{$i}->getAttr(name => 'motherboard_internal_ip')};
		push @nodes_list, $tmp;
	}
	$log->debug(Dumper($vars));
   	$template->process($input, $vars, "/tmp/".$tmpfile) || die $template->error(), "\n";
    $self->{nas}->{econtext}->send(src => "/tmp/$tmpfile", dest => "$args{mount_point}/hosts");
    unlink 	"/tmp/$tmpfile";
}

sub _generateNetConf {
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{mount_point} or ! defined $args{mount_point})) { 
		$errmsg = "EOperation::EStartNode->generateNetConf need a mount_point named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $rand = new String::Random;
	my $tmpfile = $rand->randpattern("cccccccc");

	# create Template object
	my $template = Template->new($config);
    my $input = "network_interfaces.tt";
	#TODO Get ALL network interface !
	#TODO Manage virtual IP for master node
	my $interfaces = $self->{_objs}->{cluster}->getPublicIps();
	$log->debug(Dumper($interfaces));
	$template->process($input, {interfaces => $interfaces}, "/tmp/$tmpfile") || throw Kanopya::Exception::Internal::IncorrectParam(error => "Error when generate net conf ". $template->error()."\n");
    $self->{nas}->{econtext}->send(src => "/tmp/$tmpfile", dest => "$args{mount_point}/network/interfaces");	
	unlink "/tmp/$tmpfile"; 
}

sub _generateBootConf {
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{mount_point} or ! defined $args{mount_point})) { 
		$errmsg = "EOperation::EStartNode->generateBootConf need a mount_point named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $rand = new String::Random;
	my $tmpfile = $rand->randpattern("cccccccc");

	# create Template object
	my $template = Template->new($config);
    my $input = "bootconf.tt";
#	my $adm = Administrator->new();
	
	my $root_target_id = $self->{_objs}->{component_export}->_getEntity()->getTargetIdLike(iscsitarget1_target_name => '%'."$args{root_dev}->{lvname}");
	my $root_target = $self->{_objs}->{component_export}->_getEntity()->getTarget(iscsitarget1_target_id => $root_target_id);
	my $vars ={ root_fs			=> $args{root_dev}->{filesystem},
				etc_fs			=> $args{etc_dev}->{filesystem},
				initiatorname	=> $args{initiatorname},
				etc_target		=> $args{etc_export}->{iscsitarget1_target_name},
   	    		etc_ip			=> $self->{nas}->{obj}->getMasterNodeIp(),
				etc_port		=> "3260",
				root_target		=> $root_target->{target},
   	    		root_ip			=> $self->{nas}->{obj}->getMasterNodeIp(),
				root_port		=> "3260",
				mounts_iscsi		=> []
	};
    $vars->{additional_devices} = "etc";
	my $components = $self->{_objs}->{components};
	foreach my $i (keys %$components) {
		if ($components->{$i}->isa("Entity::Component::Exportclient")) {
			if ($components->{$i}->isa("Entity::Component::Exportclient::Openiscsi2")){
				my $iscsi_export = $components->{$i};
				$vars->{mounts_iscsi} = $iscsi_export->getExports();
                my $tmp = $vars->{mounts_iscsi};
                foreach my $j (@$tmp){
                    $vars->{additional_devices} .= " ". $j->{name};
                }
   			}
		}
	}
	$log->debug(Dumper $vars);
	$template->process($input, $vars, "/tmp/$tmpfile") || throw Kanopya::Exception::Internal(error=>"EOperation::EAddMotherboard->GenerateNetConf error when parsing template");
	#TODO problem avec fichier de boot a voir.
    my $tftp_conf = $self->{_objs}->{component_tftpd}->_getEntity()->getConf();
    my $dest = $tftp_conf->{'repository'}.'/'. $self->{_objs}->{motherboard}->getAttr(name => "motherboard_hostname") . ".conf";
    $self->{nas}->{econtext}->send(src => "/tmp/$tmpfile", dest => "$dest");
    unlink "/tmp/$tmpfile";
}

sub _generateResolvConf{
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{mount_point} or ! defined $args{mount_point})) { 
		$errmsg = "EOperation::EStartNode->generateResolvConf need a mount_point named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $rand = new String::Random;
	my $tmpfile = $rand->randpattern("cccccccc");
	
	my @nameservers = ();
	# TODO manage more than only one nameserver !
	push @nameservers, { ipaddress => $self->{_objs}->{cluster}->getAttr(name => 'cluster_nameserver'), };
	
	my $vars = {
		domainname => $self->{_objs}->{cluster}->getAttr(name => 'cluster_domainname'),
		nameservers => \@nameservers, 
	};
	
	my $template = Template->new($config);
    my $input = "resolv.conf.tt";
	
	$template->process($input, $vars, "/tmp/".$tmpfile) || die $template->error(), "\n";
	$self->{nas}->{econtext}->send(src => "/tmp/$tmpfile", dest => "$args{mount_point}/resolv.conf");	
	unlink "/tmp/$tmpfile";
}

1;
__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
