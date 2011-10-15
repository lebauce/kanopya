# EStartNode.pm - Operation class implementing Cluster creation operation

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
use General;

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

    General::checkParams(args => \%args, required => ["internal_cluster"]);

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

    # Instanciate bootserver Cluster
    $self->{bootserver}->{obj} = Entity::Cluster->get(id => $args{internal_cluster}->{bootserver});
    $log->debug("Bootserver Cluster get with ref : " . ref($self->{bootserver}->{obj}));


    $self->loadContext(internal_cluster => $args{internal_cluster}, service => "nas");
    $self->loadContext(internal_cluster => $args{internal_cluster}, service => "bootserver");
    $self->loadContext(internal_cluster => $args{internal_cluster}, service => "executor");

    #### Get cluster components Entities
    $log->debug("Load cluster component instances");
    $self->{_objs}->{components}= $self->{_objs}->{cluster}->getComponents(category => "all");
    $log->debug("Load all component from cluster");

    ## Instanciate Component needed (here LVM, ISCSITARGET, DHCP and TFTPD on nas and bootserver cluster)
    # Instanciate Storage component.
    my $tmp = $self->{nas}->{obj}->getComponent(name=>"Lvm",
                                         version => "2");
    $self->{_objs}->{component_storage} = EFactory::newEEntity(data => $tmp);
    $log->debug("Load Lvm component version 2, it ref is " . ref($self->{_objs}->{component_storage}));
    # Instanciate Export component.
    $self->{_objs}->{component_export} = EFactory::newEEntity(data => $self->{nas}->{obj}->getComponent(name=>"Iscsitarget",
                                                                                      version=> "1"));
    $log->debug("Load export component (iscsitarget version 1, it ref is " . ref($self->{_objs}->{component_export}));
    # Instanciate tftpd component.
    $self->{_objs}->{component_tftpd} = EFactory::newEEntity(data => $self->{bootserver}->{obj}->getComponent(name=>"Atftpd",
                                                                                      version=> "0"));

    $log->debug("Load tftpd component (Atftpd version 0.7, it ref is " . ref($self->{_objs}->{component_tftpd}));
    # instanciate dhcpd component.
    $self->{_objs}->{component_dhcpd} = EFactory::newEEntity(data => $self->{bootserver}->{obj}->getComponent(name=>"Dhcpd",
                                                                                      version=> "3"));

    $log->debug("Load dhcp component (Dhcpd version 3, it ref is " . ref($self->{_objs}->{component_tftpd}));

}

sub _cancel {
    my $self = shift;

    my $params = $self->_getOperation()->getParams();
    my $motherboard = Entity::Motherboard->get(id => $params->{motherboard_id});
    $log->info("Cancel start node, we will try to remove node link for <" . $motherboard->getAttr(name=>"motherboard_mac_address") . ">");
    $motherboard->stopToBeNode();
    my $cluster = Entity::Cluster->get(id => $params->{cluster_id});
    my $motherboards = $cluster->getMotherboards();
    if (! scalar keys %$motherboards) {
        $cluster->setState("down");
    }
}

sub execute {
    my $self = shift;
    my $adm = Administrator->new();

    ## Clone system image etc on motherboard etc
    # Get system image etc
    my $sysimg_dev = $self->{_objs}->{cluster}->getSystemImage()->getDevices();
    my $node_dev = $self->{_objs}->{motherboard}->getEtcDev();
    # copy of systemimage etc source to motherboard etc device
    my $command = "dd if=/dev/$sysimg_dev->{etc}->{vgname}/$sysimg_dev->{etc}->{lvname} of=/dev/$node_dev->{etc}->{vgname}/$node_dev->{etc}->{lvname} bs=1M";
    my $result = $self->{nas}->{econtext}->execute(command => $command);
    $log->info("Clone node etc disk with system image <".$self->{_objs}->{cluster}->getSystemImage()->getAttr(name=>"systemimage_name")."> one");

    ## Update export to allow to motherboard to boot
    #TODO Update export root and etc to add motherboard as allowed to access to this disk

    # Generate the target name from the motherboard etc device
    my $target_name = $self->{_objs}->{component_export}->generateTargetname(name => $self->{_objs}->{motherboard}->getEtcName());


    ## ADD Motherboard in the dhcp
    my $subnet = $self->{_objs}->{component_dhcpd}->_getEntity()->getInternalSubNetId();
    my $motherboard_ip = $adm->{manager}->{network}->getFreeInternalIP();
    # Set Hostname
    my $motherboard_hostname = $self->{_objs}->{motherboard}->getAttr(name => "motherboard_hostname");
    if(not $motherboard_hostname) {
        $motherboard_hostname = $self->{_objs}->{motherboard}->generateHostname(ip=>$motherboard_ip);
        $self->{_objs}->{motherboard}->setAttr(name => "motherboard_hostname",
                                           value => $motherboard_hostname);
    }

    # Set initiatorName
    $self->{_objs}->{motherboard}->setAttr(name => "motherboard_initiatorname",
                                           value => $self->{_objs}->{component_export}->generateInitiatorname(hostname => $self->{_objs}->{motherboard}->getAttr(name=>'motherboard_hostname')));

    # Configure DHCP Component
    my $motherboard_mac = $self->{_objs}->{motherboard}->getAttr(name => "motherboard_mac_address");
    my $motherboard_kernel_id;
    my $tmp_kernel_id = $self->{_objs}->{cluster}->getAttr(name => "kernel_id");
    if ($tmp_kernel_id) {
        $motherboard_kernel_id = $tmp_kernel_id;
    } else {
        $motherboard_kernel_id = $self->{_objs}->{motherboard}->getAttr(name => "kernel_id");
    }

    $self->{_objs}->{component_dhcpd}->addHost( dhcpd3_subnet_id                => $subnet,
                                                dhcpd3_hosts_ipaddr             => $motherboard_ip,
                                                dhcpd3_hosts_mac_address        => $motherboard_mac,
                                                dhcpd3_hosts_hostname           => $motherboard_hostname,
                                                dhcpd3_hosts_ntp_server         => $self->{bootserver}->{obj}->getMasterNodeIp(),
                                                dhcpd3_hosts_domain_name        => $self->{_objs}->{cluster}->getAttr(name => "cluster_domainname"),
                                                dhcpd3_hosts_domain_name_server => $self->{_objs}->{cluster}->getAttr(name => "cluster_nameserver"),
                                                kernel_id                       => $motherboard_kernel_id,
                                                erollback                       => $self->{erollback});
    my $eroll_add_dhcp_host = $self->{erollback}->getLastInserted();
    # generate new configuration file
    $self->{erollback}->insertNextErollBefore(erollback=>$eroll_add_dhcp_host);
    $self->{_objs}->{component_dhcpd}->generate(econtext    => $self->{bootserver}->{econtext},
                                                erollback   => $self->{erollback});
    my $eroll_dhcp_generate = $self->{erollback}->getLastInserted();
    # generate new configuration file
    $self->{erollback}->insertNextErollBefore(erollback=>$eroll_dhcp_generate);
    $self->{_objs}->{component_dhcpd}->reload(econtext  => $self->{bootserver}->{econtext},
                                              erollback => $self->{erollback});
    $log->info('Update Admin Dhcp server');

    #Update Motherboard internal ip
    $log->info("get subnet <$subnet>");
    my %subnet_hash = $self->{_objs}->{component_dhcpd}->_getEntity()->getSubNet(dhcpd3_subnet_id => $subnet);

    my $ipv4_internal_id = $self->{_objs}->{motherboard}->setInternalIP(ipv4_address => $motherboard_ip,
                                                 ipv4_mask => $subnet_hash{'dhcpd3_subnet_mask'});

    # Mount Motherboard etc to populate it
    my $mkdir_cmd = "mkdir -p /mnt/$node_dev->{etc}->{lvname}";
    $self->{nas}->{econtext}->execute(command => $mkdir_cmd);
    my $mount_cmd = "mount /dev/$node_dev->{etc}->{vgname}/$node_dev->{etc}->{lvname} /mnt/$node_dev->{etc}->{lvname}";
    $self->{nas}->{econtext}->execute(command => $mount_cmd);

#   Later we may need to have node list to create new node conf
#    my $clust_nodes = $self->{_objs}->{cluster}->getMotherboards();
    # Generate Node configuration
    $self->_generateNodeConf(mount_point => "/mnt/$node_dev->{etc}->{lvname}",
                             root_dev     => $sysimg_dev->{root},
                             etc_dev        => $node_dev->{etc},
                             etc_targetname    => $target_name);



    #TODO  component migrate (node, exec context?)
    my $components = $self->{_objs}->{components};
    $log->info('Processing cluster components configuration for this node');
    foreach my $i (keys %$components) {
        my $tmp = EFactory::newEEntity(data => $components->{$i});
        $log->debug("component is ".ref($tmp));
        $tmp->addNode(motherboard   => $self->{_objs}->{motherboard},
                      mount_point   => "/mnt/$node_dev->{etc}->{lvname}",
                      cluster       => $self->{_objs}->{cluster},
                      econtext      => $self->{nas}->{econtext},
                      erollback     => $self->{erollback});
    }

    # Umount Motherboard etc
    my $sync_cmd = "sync";
    $self->{nas}->{econtext}->execute(command => $sync_cmd);
    my $umount_cmd = "umount /mnt/$node_dev->{etc}->{lvname}";
    $self->{nas}->{econtext}->execute(command => $umount_cmd);
    my $rmdir_cmd = "rmdir /mnt/$node_dev->{etc}->{lvname}";
    $self->{nas}->{econtext}->execute(command => $rmdir_cmd);

    # Create node instance
    $self->{_objs}->{motherboard}->setNodeState(state=>"goingin");
    $self->{_objs}->{motherboard}->save();

    # Generate node etc export
    ################################################################################
    $self->{_objs}->{component_export}->addExport(iscsitarget1_lun_number    => 0,
                                                iscsitarget1_lun_device    => "/dev/$node_dev->{etc}->{vgname}/$node_dev->{etc}->{lvname}",
                                                iscsitarget1_lun_typeio    => "fileio",
                                                iscsitarget1_lun_iomode    => "wb",
                                                iscsitarget1_target_name=>$target_name,
                                                econtext                 => $self->{nas}->{econtext},
                                                erollback               => $self->{erollback});
    my $eroll_add_export = $self->{erollback}->getLastInserted();
    # generate new configuration file
    $self->{erollback}->insertNextErollBefore(erollback=>$eroll_add_export);
    $self->{_objs}->{component_export}->generate(econtext   => $self->{nas}->{econtext},
                                                 erollback  => $self->{erollback});

    # finaly we start the node
    my $emotherboard = EFactory::newEEntity(data => $self->{_objs}->{motherboard});
    $emotherboard->start(econtext =>$self->{executor}->{econtext},erollback => $self->{erollback});
}

sub _generateNodeConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args=>\%args, required => ["mount_point","root_dev","etc_dev","etc_targetname"]);

    my $hostname = $self->{_objs}->{motherboard}->getAttr(name => "motherboard_hostname");
    $log->info("Generate Hostname Conf");
    $self->_generateHostnameConf(hostname => $hostname, mount_point=>$args{mount_point});

    my $initiatorname = $self->{_objs}->{motherboard}->getAttr(name => "motherboard_initiatorname");
    $log->info("Generate Initiator Conf");
    $self->_generateInitiatorConf(initiatorname => $initiatorname, mount_point=>$args{mount_point});

    $log->info("Generate Udev Conf");
    $self->_generateUdevConf(mount_point=>$args{mount_point});

    # /etc/fstab is now managed by mounttable1 system component

    #$self->_generateFstabConf(    mount_point=>$args{mount_point},
    #                            root_dev => $args{root_dev},
    #                            etc_dev => $args{etc_dev});

    $log->info("Generate Kanopya Halt script Conf");
    $self->_generateKanopyaHalt(mount_point=>$args{mount_point}, etc_targetname => $args{etc_targetname});
#    $log->info("Generate Hosts Conf");
#    $self->generateHosts(mount_point=>$args{mount_point}, nodes => $args{nodes});

    $log->info("Generate Network Conf");
    $self->_generateNetConf(mount_point=>$args{mount_point});



    $log->info("Generate resolv.conf");
    $self->_generateResolvConf(mount_point=>$args{mount_point});
#TODO generateRouteConf

    $log->info("Generate Boot Conf");
    $self->_generateBootConf(initiatorname => $initiatorname,
                            root_dev => $args{root_dev},
                            etc_dev => $args{etc_dev},
                            etc_targetname => $args{etc_targetname});##############

    $log->info("Generate ntpdate Conf");
    $self->_generateNtpdateConf(mount_point=>$args{mount_point});
}

sub _generateHostnameConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args=>\%args, required => ["mount_point","hostname"]);

    $self->{nas}->{econtext}->execute(command => "echo $args{hostname} > $args{mount_point}/hostname");
}

sub _generateInitiatorConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args=>\%args, required => ["mount_point","initiatorname"]);

    $self->{nas}->{econtext}->execute(command=>"echo \"InitiatorName=$args{initiatorname}\" > $args{mount_point}/iscsi/initiatorname.iscsi");
}

sub _generateUdevConf{
    my $self = shift;
    my %args = @_;

    General::checkParams(args=>\%args, required => ["mount_point"]);

    my $rand = new String::Random;
    my $tmpfile = $rand->randpattern("cccccccc");
    # create Template object
    my $template = Template->new($config);
    my $input = "udev_70-persistent-net.rules.tt";

    #TODO Get ALL network interface !
    my $interfaces = [{mac_address => lc($self->{_objs}->{motherboard}->getAttr(name => "motherboard_mac_address")), net_interface => "eth0"}];
    $log->debug("generateUdevConf with ".Dumper($interfaces));
    $template->process($input, {interfaces => $interfaces}, "/tmp/".$tmpfile) || die $template->error(), "\n";
    $self->{nas}->{econtext}->send(src => "/tmp/$tmpfile", dest => "$args{mount_point}/udev/rules.d/70-persistent-net.rules");
    unlink "/tmp/$tmpfile";
}

sub _generateKanopyaHalt{
    my $self = shift;
    my %args = @_;

    General::checkParams(args=>\%args, required => ["mount_point","etc_targetname"]);

    my $rand = new String::Random;
    my $template = Template->new($config);
    my $tmpfile = $rand->randpattern("cccccccc");
    my $tmpfile2 = $rand->randpattern("cccccccc");
    my $input = "KanopyaHalt.tt";
    my $omitted_file = "Kanopya_omitted_iscsid";
    #TODO mettre en parametre le port du iscsi du nas!!
    my $vars = {etc_target        => $args{etc_targetname},
                   nas_ip            => $self->{nas}->{obj}->getMasterNodeIp(),
                nas_port        => "3260",
    };
    my $components = $self->{_objs}->{components};
    foreach my $i (keys %$components) {
        my $tmp = $components->{$i};
        #TODO Check if it is an ExportClient and call generic method/
        if ($components->{$i}->isa("Entity::Component")) {
            if ($components->{$i}->isa("Entity::Component::Openiscsi2")){
                $log->debug("The cluster component is an Openiscsi2");
                my $iscsi_export = $components->{$i};
                $vars->{data_exports} = $iscsi_export->getExports();
               }
        }
    }
    $log->debug("Generate Kanopya Halt with :".Dumper($vars));
    $template->process($input, $vars, "/tmp/".$tmpfile) || die $template->error(), "\n";
    $self->{nas}->{econtext}->send(src => "/tmp/$tmpfile", dest => "$args{mount_point}/init.d/Kanopya_halt");
    unlink "/tmp/$tmpfile";
    $self->{nas}->{econtext}->execute(command=> "chmod 755 $args{mount_point}/init.d/Kanopya_halt");
    $self->{nas}->{econtext}->execute(command=> "ln -sf ../init.d/Kanopya_halt $args{mount_point}/rc0.d/S89Kanopya_halt");

    $log->debug("Generate omitted file <$omitted_file>");
    $self->{nas}->{econtext}->execute(command=> "cp /templates/internal/$omitted_file /tmp/");
    $self->{nas}->{econtext}->send(src => "/tmp/$omitted_file", dest => "$args{mount_point}/init.d/Kanopya_omitted_iscsid");
    unlink "/tmp/$omitted_file";
    $self->{nas}->{econtext}->execute(command=> "chmod 755 $args{mount_point}/init.d/Kanopya_omitted_iscsid");
    $self->{nas}->{econtext}->execute(command=> "ln -sf ../init.d/Kanopya_omitted_iscsid $args{mount_point}/rc0.d/S19Kanopya_omitted_iscsid");
}

sub _generateHosts {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ["mount_point"]);

    my $rand = new String::Random;
    my $tmpfile = $rand->randpattern("cccccccc");

    # create Template object
    my $template = Template->new($config);
    my $input = "hosts.tt";
    my $nodes = $args{nodes};
    my @nodes_list = ();
    my $vars = {hostname        => $self->{_objs}->{motherboard}->getAttr(name => "motherboard_hostname"),
                   domainname            => "hedera-technology.com",
                hosts        => \@nodes_list,
          };
    foreach my $i (keys %$nodes) {
        my $tmp = {hostname     => $nodes->{$i}->getAttr(name => 'motherboard_hostname'),
                   domainname    => "hedera-technology.com",
                   ip            => $nodes->{$i}->getInternalIP()->{ipv4_internal_address}};
        push @nodes_list, $tmp;
    }
    $log->debug(Dumper($vars));
       $template->process($input, $vars, "/tmp/".$tmpfile) || die $template->error(), "\n";
    $self->{nas}->{econtext}->send(src => "/tmp/$tmpfile", dest => "$args{mount_point}/hosts");
    unlink     "/tmp/$tmpfile";
}

sub _generateNetConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['mount_point']);

    my $rand = new String::Random;
    my $tmpfile = $rand->randpattern("cccccccc");

    # create Template object
    my $template = Template->new($config);
    my $input = "network_interfaces.tt";
    #TODO Get ALL network interface !
    #TODO Manage virtual IP for master node
    my @interfaces = ();
    my $ip = $self->{_objs}->{motherboard}->getInternalIP();
    my %model = $self->{_objs}->{motherboard}->getModel();

    my $need_bridge= 0;
    my $components = $self->{_objs}->{components};
    while(my ($id, $component) = each %$components) {
        $log->debug(ref($component)." need_bridge: ".$component->needBridge());
        if($component->needBridge()) {
            $need_bridge = 1;
            last;
        }
    }

    my $iface = { name => 'eth0', address => $ip->{ipv4_internal_address}, netmask => $ip->{ipv4_internal_mask}};
    if($need_bridge) {
        $iface->{name} = 'br0';
        $iface->{bridge} = 1;
        $iface->{bridge_ports} = 'eth0';
        $iface->{bridge_stp} = 'off';
        $iface->{bridge_fd} = 2;
        $iface->{bridge_maxwait} = 0;
    }

    push(@interfaces, $iface);


    if (not $self->{_objs}->{cluster}->getMasterNodeId()) {
        my $i =0;
        my $tiers = $self->{_objs}->{cluster}->getTiers();
        if ($tiers) {
            foreach my $tier_key (keys %$tiers){
                my $dmz_ips = $tiers->{$tier_key}->getDmzIps();
                foreach my $dmz_ip (@$dmz_ips){
                    my $tmp_iface = {name => "eth0:$i", address => $dmz_ip->{address}, netmask => $dmz_ip->{netmask}};
                    push (@interfaces, $tmp_iface);
                    $i++;
                }
            }
        }
        @interfaces = (@interfaces, @{$self->{_objs}->{cluster}->getPublicIps()});
    }

    $log->debug(Dumper(@interfaces));
    $template->process($input, {interfaces => \@interfaces}, "/tmp/$tmpfile") || throw Kanopya::Exception::Internal::IncorrectParam(error => "Error when generate net conf ". $template->error()."\n");
    $self->{nas}->{econtext}->send(src => "/tmp/$tmpfile", dest => "$args{mount_point}/network/interfaces");
    unlink "/tmp/$tmpfile";

    # disable network deconfiguration during halt
    unlink "$args{mount_point}/rc0.d/S35networking";

}

sub _generateBootConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args =>\%args, required=>[ "root_dev","etc_targetname","initiatorname", "etc_dev",]);

    my $rand = new String::Random;
    my $tmpfile = $rand->randpattern("cccccccc");

    # create Template object
    my $template = Template->new($config);
    my $input = "bootconf.tt";

    my $root_target_id = $self->{_objs}->{component_export}->_getEntity()->getTargetIdLike(iscsitarget1_target_name => '%'."$args{root_dev}->{lvname}");
    my $root_targetname = $self->{_objs}->{component_export}->_getEntity()->getTargetName(iscsitarget1_target_id => $root_target_id);
    my $root_options = $self->{_objs}->{cluster}->getAttr(name => 'cluster_si_shared') ? "ro,noatime,nodiratime":"defaults";
    my $vars ={ root_fs            => $args{root_dev}->{filesystem},
                etc_fs            => $args{etc_dev}->{filesystem},
                initiatorname    => $args{initiatorname},
                etc_target        => $args{etc_targetname},
                   etc_ip            => $self->{nas}->{obj}->getMasterNodeIp(),
                etc_port        => "3260",
                root_target        => $root_targetname,
                   root_ip            => $self->{nas}->{obj}->getMasterNodeIp(),
                root_port        => "3260",
                root_mount_opts => $root_options,
                mounts_iscsi        => []
    };
    $vars->{additional_devices} = "etc";
    my $components = $self->{_objs}->{components};
    foreach my $i (keys %$components) {
        if ($components->{$i}->isa("Entity::Component")) {
            if ($components->{$i}->isa("Entity::Component::Openiscsi2")){
                my $iscsi_export = $components->{$i};
                $vars->{mounts_iscsi} = $iscsi_export->getExports();
                my $tmp = $vars->{mounts_iscsi};
                foreach my $j (@$tmp){
                    $vars->{additional_devices} .= " ". $j->{name};
                }
               }
        }
    }
#    $log->debug(Dumper $vars);
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

    General::checkParams(args => \%args, required => ['mount_point']);

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

sub _generateNtpdateConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args=>\%args, required => ["mount_point"]);

    my $rand = new String::Random;
    my $tmpfile = $rand->randpattern("cccccccc");
    my $template = Template->new($config);
    my $input = "ntpdate.tt";
    my $data = {
      ntpservers => $self->{bootserver}->{obj}->getMasterNodeIp(),
    };
    $template->process($input, $data, "/tmp/$tmpfile") || throw Kanopya::Exception::Internal::IncorrectParam(error => "Error when generate ntpdate conf ". $template->error()."\n");
    $self->{nas}->{econtext}->send(src => "/tmp/$tmpfile", dest => "$args{mount_point}/default/ntpdate");
    unlink "/tmp/$tmpfile";
}

1;
__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
