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

package EOperation::EStartNode;
use base "EOperation";

use strict;
use warnings;

use String::Random;
use Date::Simple (':all');

use Kanopya::Exceptions;
use EFactory;
use Entity::ServiceProvider;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Host;
use Entity::Kernel;
use Template;
use General;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';

my $config = General::getTemplateConfiguration();

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    General::checkParams(args => \%args, required => ["internal_cluster"]);

    my $params = $self->_getOperation()->getParams();

    General::checkParams(args => $params, required => [ "cluster_id", "host_id" ]);

    $self->{executor}   = {};
    $self->{bootserver} = {};
    $self->{_objs}      = {};

    # Cluster instantiation
    $log->debug("checking cluster existence with id <$params->{cluster_id}>");
    eval {
        $self->{_objs}->{cluster} = Entity::ServiceProvider::Inside::Cluster->get(
                                        id => $params->{cluster_id}
                                    );
    };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::EStartNode->prepare : cluster_id $params->{cluster_id} does not find\n" . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    # Host instantiation
    $log->debug("checking Host existence with id <$params->{host_id}>");
    eval {
        $self->{_objs}->{host} = Entity::Host->get(id => $params->{host_id});
    };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::EStartNode->prepare : host_id $params->{host_id} does not find\n" . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    # Instanciate bootserver Cluster
    $self->{bootserver}->{obj} = Entity::ServiceProvider::Inside::Cluster->get(
                                     id => $args{internal_cluster}->{bootserver}
                                 );

    $log->debug("Bootserver Cluster get with ref : " . ref($self->{bootserver}->{obj}));

    $self->loadContext(internal_cluster => $args{internal_cluster}, service => "bootserver");
    $self->loadContext(internal_cluster => $args{internal_cluster}, service => "executor");

    # Get cluster components Entities
    $log->debug("Load cluster component instances");
    $self->{_objs}->{components}= $self->{_objs}->{cluster}->getComponents(category => "all");

    # Instanciate tftpd component.
    my $tftp_component = $self->{bootserver}->{obj}->getComponent(name => "Atftpd", version => "0");
    $self->{_objs}->{component_tftpd} = EFactory::newEEntity(data => $tftp_component);

    $log->debug("Loaded tftpd component (Atftpd version 0.7, it ref is " . ref($self->{_objs}->{component_tftpd}));

    # Instanciate dhcpd component.
    my $dhcp_component = $self->{bootserver}->{obj}->getComponent(name => "Dhcpd", version => "3");
    $self->{_objs}->{component_dhcpd} = EFactory::newEEntity(data => $dhcp_component);

    $log->debug("Loaded dhcp component (Dhcpd version 3, it ref is " . ref($self->{_objs}->{component_tftpd}));

    # Get container of the system image, get the container access of the container
    $self->{_objs}->{container} = $self->{_objs}->{host}->getNodeSystemimage->getDevice;

    # Warning:
    # 1. Systeme image should be activated, so at least one container access exists
    # 2. As systemimages always dedicated for instance, a system image container has
    #    onlky one container access.
    $self->{_objs}->{container_access} = pop @{ $self->{_objs}->{container}->getAccesses };

}

sub _cancel {
    my $self = shift;

    my $params = $self->_getOperation()->getParams();
    my $host = Entity::Host->get(id => $params->{host_id});

    $log->info("Cancel start node, we will try to remove node link for <" .
               $host->getAttr(name => "entity_id") . ">");

    $host->stopToBeNode();

    my $cluster = Entity::ServiceProvider::Inside::Cluster->get(id => $params->{cluster_id});
    my $hosts = $cluster->getHosts();
    if (! scalar keys %$hosts) {
        $cluster->setState(state => "down");
    }
}

sub execute {
    my $self = shift;

    # Firstly compute the node configuration
    $log->info("Compute node configuration for host <" . $self->{_objs}->{host}->getAttr(name => "entity_id"));
    if ((exists $self->{_objs}->{powersupplycard} and defined $self->{_objs}->{powersupplycard}) and
        (exists $self->{_objs}->{powersupplyport_number} and defined $self->{_objs}->{powersupplyport_number})) {
        my $powersupply_id = $self->{_objs}->{powersupplycard}->addPowerSupplyPort(
                                 powersupplyport_number => $self->{_objs}->{powersupplyport_number}
                             );

        $self->{_objs}->{host}->setAttr(name  => 'host_powersupply_id',
                                        value => $powersupply_id);
    }

    my ($access_mode, $mount_options) = $self->{_objs}->{cluster}->getAttr(name => 'cluster_si_shared')
                      ? ("ro", "ro,noatime,nodiratime") : ("rw", "defaults");

    # Get the ECluster and EHost
    my $ecluster = EFactory::newEEntity(data => $self->{_objs}->{cluster});
    my $ehost = EFactory::newEEntity(data => $self->{_objs}->{host});

    # Get the corresponding EContainerAccess
    my $econtainer_access = EFactory::newEEntity(data => $self->{_objs}->{container_access});
    my $eexport_manager = EFactory::newEEntity(data => $self->{_objs}->{container_access}->getExportManager);

    # Mount the containers on the executor.
    my $mountpoint = $self->{_objs}->{container}->getMountPoint;

    $log->info('Mounting the container <' . $mountpoint . '>');
    $econtainer_access->mount(mountpoint => $mountpoint,
                              econtext => $self->{executor}->{econtext});

    # generate resolv.conf
    $ecluster->generateResolvConf(
        etc_path => $mountpoint . '/etc',
        econtext => $self->{executor}->{econtext}
    );

    # generate node hostname
    $ehost->generateHostname(
        etc_path => $mountpoint . '/etc',
        econtext => $self->{executor}->{econtext}
    );

    # generate node udev persistent net rules
    $ehost->generateUdevPersistentNetRules(
        etc_path => $mountpoint . '/etc',
        econtext => $self->{executor}->{econtext}
    );

    $log->info("Generate Boot Conf");

    # Apply node boot configuration
    $self->_generateBootConf(mountpoint => $mountpoint,
                             filesystem => $self->{_objs}->{container}->getAttr(
                                               name => 'container_filesystem'
                                           ),
                             options    => $mount_options);

    # Apply node etc configuration
    $self->_generateNodeConf(etc_path => $mountpoint . '/etc',
                             options  => $mount_options);

    # TODO: Component migration (node, exec context?)
    my $components = $self->{_objs}->{components};
    foreach my $i (keys %$components) {
        my $ecomponent = EFactory::newEEntity(data => $components->{$i});
        $log->debug("component is " . ref($ecomponent));
        $ecomponent->addNode(host        => $self->{_objs}->{host},
                             mount_point => $mountpoint,
                             cluster     => $self->{_objs}->{cluster},
                             econtext    => $self->{executor}->{econtext},
                             erollback   => $self->{erollback});
    }

    # Umount system image container
    $econtainer_access->umount(mountpoint => $mountpoint,
                               econtext   => $self->{executor}->{econtext});

    # Give access to the system image to the node
    $log->info('Giving access to the system image to the node');
    $eexport_manager->addExportClient(
        export  => $self->{_objs}->{container_access},
        host    => $self->{_objs}->{host},
        options => $access_mode
    );

    # Create node instance
    $self->{_objs}->{host}->setNodeState(state => "goingin");
    $self->{_objs}->{host}->save();

    # Finally we start the node
    $ehost->start(
        econtext  => $self->{executor}->{econtext},
        erollback => $self->{erollback}
    );
}

sub _generateNodeConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args,
                         required => [ "etc_path", "options" ]);

    $log->info("Generate Network Conf");
    $self->_generateNetConf(etc_path => $args{etc_path});

    # TODO generateRouteConf

    $log->info("Generate ntpdate Conf");
    $self->_generateNtpdateConf(etc_path => $args{etc_path});
}

sub _generateNetConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'etc_path' ]);

    my $rand = new String::Random;
    my $tmpfile = $rand->randpattern("cccccccc");

    # Create Template object
    my $template = Template->new($config);
    my $input = "network_interfaces.tt";

    my @cluster_interfaces = ();
    my @host_ifaces = $self->{_objs}->{host}->getIfaces();
    my @interfaces = ();
    my $ip = $self->{_objs}->{host}->getInternalIP();
    
    foreach my $iface (@host_ifaces) {
        next if $iface->{iface_pxe} eq "1";
        if($iface->{iface_name} eq 'eth0') { 
            my $iface = {
                name    => $iface->{iface_name},
                address => $ip->{ipv4_internal_address},
                netmask => $ip->{ipv4_internal_mask}
            }; 
            push(@interfaces, $iface);
        }
    }
    
    #my $ip = $self->{_objs}->{host}->getInternalIP();
    #my %model = $self->{_objs}->{host}->getModel();

    #~ my $need_bridge = 0;
    #~ my $components = $self->{_objs}->{components};
    #~ while (my ($id, $component) = each %$components) {
        #~ $log->debug(ref($component) . " need_bridge: " . $component->needBridge());
        #~ if ($component->needBridge()) {
            #~ $need_bridge = 1;
            #~ last;
        #~ }
    #~ }

    



    #~ if($need_bridge) {
        #~ $iface->{name}           = 'br0';
        #~ $iface->{bridge_ports}   = 'eth0';
        #~ $iface->{bridge_stp}     = 'off';
        #~ $iface->{bridge}         = 1;
        #~ $iface->{bridge_fd}      = 2;
        #~ $iface->{bridge_maxwait} = 0;
    #~ }

    

    if (not $self->{_objs}->{cluster}->getMasterNodeId()) {
        my $i = 1;
        my $tiers = $self->{_objs}->{cluster}->getTiers();
        if ($tiers) {
            foreach my $tier_key (keys %$tiers){
                my $dmz_ips = $tiers->{$tier_key}->getDmzIps();
                foreach my $dmz_ip (@$dmz_ips){
                    my $tmp_iface = {
                        name    => "eth0:$i",
                        address => $dmz_ip->{address},
                        netmask => $dmz_ip->{netmask}
                    };
                    push (@interfaces, $tmp_iface);
                    $i++;
                }
            }
        }
        @interfaces = (@interfaces, @{$self->{_objs}->{cluster}->getPublicIps()});
    }

    #$log->debug(Dumper(@interfaces));
    $template->process($input, { interfaces => \@interfaces }, "/tmp/$tmpfile")
        or throw Kanopya::Exception::Internal::IncorrectParam(
                     error => "Error when generate net conf ". $template->error() . "\n"
                 );

    $self->{executor}->{econtext}->send(
        src => "/tmp/$tmpfile",
        dest => "$args{etc_path}/network/interfaces"
    );
    unlink "/tmp/$tmpfile";

    # Disable network deconfiguration during halt
    unlink "$args{etc_path}/rc0.d/S35networking";
}

sub _generateBootConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     =>\%args,
                         required => [ "mountpoint", "filesystem", "options" ]);

    my $etc_path = $args{mountpoint} . '/etc';

    # Firstly create pxe config file if needed
    my $boot_policy = $self->{_objs}->{cluster}->getAttr(name => 'cluster_boot_policy');

    if ($boot_policy =~ m/PXE/) {
        $self->_generatePXEConf(cluster    => $self->{_objs}->{cluster},
                                host       => $self->{_objs}->{host},
                                mountpoint => $args{mountpoint});

        if ($boot_policy =~ m/ISCSI/) {
            my $targetname = $self->{_objs}->{container_access}->getAttr(name => 'container_access_export');

            #$log->info("Generate Kanopya Halt script Conf");

            #$self->_generateKanopyaHalt(etc_path   => $etc_path,
            #                            targetname => $targetname);

            $self->{executor}->{econtext}->execute(
                command => "touch $etc_path/iscsi.initramfs"
            );

            $log->info("Generate Initiator Conf");

            # Here we compute an iscsi initiator name for the node
            my $date = today();
            my $year = $date->year;
            my $month = $date->month;
            if(length($month) == 1) {
                $month = '0'.$month;
            }
            my $initiatorname = 'iqn.'.$year.'-'.$month.'.';
            $initiatorname .= $self->{_objs}->{cluster}->getAttr(name => 'cluster_name');
            $initiatorname .= '.'.$self->{_objs}->{host}->getAttr(name => 'host_hostname');
            $initiatorname .= ':'.time();

            my $lun_number = $self->{_objs}->{container_access}->getAttr(name => 'lun_name')
                             || "lun-0";

            # Set initiatorName
            $self->{_objs}->{host}->setAttr(name  => "host_initiatorname",
                                            value => $initiatorname);

            $self->{executor}->{econtext}->execute(
                command => "echo \"InitiatorName=$initiatorname\" > " .
                           "$etc_path/initiatorname.iscsi"
            );

            my $rand = new String::Random;
            my $tmpfile = $rand->randpattern("cccccccc");

            # create Template object
            my $template = Template->new($config);
            my $input = "bootconf.tt";

            my $vars = {
                filesystem    => $self->{_objs}->{container}->getAttr(name => 'container_filesystem'),
                initiatorname => $initiatorname,
                target        => $targetname,
                ip            => $self->{_objs}->{container_access}->getAttr(name => 'container_access_ip'),
                port          => $self->{_objs}->{container_access}->getAttr(name => 'container_access_port'),
                lun           => $lun_number,
                mount_opts    => $args{options},
                mounts_iscsi  => [],
                additional_devices => "",
            };

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

            $template->process($input, $vars, "/tmp/$tmpfile")
                or throw Kanopya::Exception::Internal(
                             error => "Error when processing template $input."
                         );

            my $tftp_conf = $self->{_objs}->{component_tftpd}->_getEntity()->getConf();
            my $dest = $tftp_conf->{'repository'} . '/' . $self->{_objs}->{host}->getAttr(name => "host_hostname") . ".conf";

            $self->{executor}->{econtext}->send(src => "/tmp/$tmpfile", dest => "$dest");
            unlink "/tmp/$tmpfile";
        }

        my $grep_result = $self->{executor}->{econtext}->execute(
                              command => "grep \"NETDOWN=no\" $etc_path/default/halt"
                          );

        if (not $grep_result->{stdout}) {
            $self->{executor}->{econtext}->execute(
                command => "echo \"NETDOWN=no\" >> $etc_path/default/halt"
            );
        }
    }
    else {
        my $adm     = Administrator->new();
        my $subnet  = $self->{_objs}->{component_dhcpd}->_getEntity()->getInternalSubNetId();
        my $host_ip = $adm->{manager}->{network}->getFreeInternalIP();

        # Update Host internal ip
        $log->info("get subnet <$subnet> and have host ip <$host_ip>");
        my %subnet_hash = $self->{_objs}->{component_dhcpd}->_getEntity()->getSubNet(dhcpd3_subnet_id => $subnet);
            
        $self->{_objs}->{host}->setInternalIP(ipv4_address => $host_ip,
                                              ipv4_mask    => $subnet_hash{'dhcpd3_subnet_mask'});
    }
 
    # Set up fastboot
    $self->{executor}->{econtext}->execute(
        command => "touch $args{mountpoint}/fastboot"
    );
}

sub _generatePXEConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     =>\%args,
                         required => ['cluster', 'host', 'mountpoint']);

    my $cluster_kernel_id = $args{cluster}->getAttr(name => "kernel_id");
    my $kernel_id = $cluster_kernel_id ? $cluster_kernel_id : $args{host}->getAttr(name => "kernel_id");

    my $clustername = $args{cluster}->getAttr(name => 'cluster_name');
    my $hostname = $args{host}->getAttr(name => 'host_hostname'); 

    my $kernel_version   = Entity::Kernel->get(id => $kernel_id)->getAttr(name => 'kernel_version');
    my $container_access = $self->{_objs}->{container_access};
    my $boot_policy      = $args{cluster}->getAttr(name => 'cluster_boot_policy');
    
    my $tftp_conf = $self->{_objs}->{component_tftpd}->_getEntity()->getConf();

    my $nfsexport = "";
    if ($boot_policy =~ m/NFS/) {
        $nfsexport = $container_access->getAttr(name => 'container_access_export');
    }

    ## Here we create a dedicated initramfs for the node
    # create the storing directory
    my $path = $tftp_conf->{'repository'}."/$clustername/$hostname";
    my $cmd = "mkdir -p $path";
    $self->{executor}->{econtext}->execute(command => $cmd);
    
    # make a decompressed copy of the initrd to this directory
    my $initrd = $tftp_conf->{'repository'}."/initrd_$kernel_version";
    my $newinitrd = $path."/initrd_$kernel_version";
    $cmd = "bzcat $initrd > $newinitrd";
    $self->{executor}->{econtext}->execute(command => $cmd);
    
    # append files to the cpio archive
    $cmd = 'cd '.$args{mountpoint};
    $cmd .= ' && find . -name 70-persistent-net.rules';
    $cmd .= " | cpio -o -O $newinitrd -A -H newc";
    $cmd .= ' && cd -';
    $self->{executor}->{econtext}->execute(command => $cmd);
    
    # recompress the initrd in bz2
    $cmd = "bzip2 $newinitrd && mv $newinitrd.bz2 $newinitrd";
    $self->{executor}->{econtext}->execute(command => $cmd);

    my $node_mac_addr = $args{host}->getPXEMacAddress;

    # Add host in the dhcp
    my $adm     = Administrator->new();
    my $subnet  = $self->{_objs}->{component_dhcpd}->_getEntity()->getInternalSubNetId();
    my $host_ip = $adm->{manager}->{network}->getFreeInternalIP();

    # Set Hostname
    my $host_hostname = $self->{_objs}->{host}->getAttr(name => "host_hostname");

    # Configure DHCP Component
    my $host_kernel_id;
    my $tmp_kernel_id = $self->{_objs}->{cluster}->getAttr(name => "kernel_id");
    if ($tmp_kernel_id) {
        $host_kernel_id = $tmp_kernel_id;
    } else {
        $host_kernel_id = $self->{_objs}->{host}->getAttr(name => "kernel_id");
    }

    $self->{_objs}->{component_dhcpd}->addHost(
        dhcpd3_subnet_id                => $subnet,
        dhcpd3_hosts_ipaddr             => $host_ip,
        dhcpd3_hosts_mac_address        => $node_mac_addr,
        dhcpd3_hosts_hostname           => $host_hostname,
        dhcpd3_hosts_ntp_server         => $self->{bootserver}->{obj}->getMasterNodeIp(),
        dhcpd3_hosts_domain_name        => $self->{_objs}->{cluster}->getAttr(name => "cluster_domainname"),
        dhcpd3_hosts_domain_name_server => $self->{_objs}->{cluster}->getAttr(name => "cluster_nameserver1"),
        kernel_id                       => $host_kernel_id,
        erollback                       => $self->{erollback}
    );

    my $eroll_add_dhcp_host = $self->{erollback}->getLastInserted();
    $self->{erollback}->insertNextErollBefore(erollback => $eroll_add_dhcp_host);

    # Generate new configuration file
    $self->{_objs}->{component_dhcpd}->generate(econtext    => $self->{bootserver}->{econtext},
                                                erollback   => $self->{erollback});

    my $eroll_dhcp_generate = $self->{erollback}->getLastInserted();
    $self->{erollback}->insertNextErollBefore(erollback=>$eroll_dhcp_generate);

    # Generate new configuration file
    $self->{_objs}->{component_dhcpd}->reload(econtext  => $self->{bootserver}->{econtext},
                                              erollback => $self->{erollback});
    $log->info('Adming dhcp server updated');

    # Here we generate pxelinux.cfg for the host
    my $rand    = new String::Random;
    my $tmpfile = $rand->randpattern("cccccccc");

    # create Template object
    my $template = Template->new($config);
    my $input    = "node-syslinux.cfg.tt";

    my $vars = {
        nfsroot    => ($boot_policy =~ m/NFS/) ? 1 : 0,
        iscsiroot  => ($boot_policy =~ m/ISCSI/) ? 1 : 0,
        xenkernel  => ($kernel_version =~ m/xen/) ? 1 : 0,
        kernelfile => "vmlinuz-$kernel_version",
        initrdfile => "$clustername/$hostname/initrd_$kernel_version",
        nfsexport  => $nfsexport,
    };

    $template->process($input, $vars, "/tmp/$tmpfile")
        or throw Kanopya::Exception::Internal(
                     error => "Error when processing template $input."
                 );

    $node_mac_addr =~ s/:/-/g;
    my $dest = $tftp_conf->{'repository'} . '/pxelinux.cfg/01-' . lc $node_mac_addr;

    $self->{executor}->{econtext}->send(src => "/tmp/$tmpfile", dest => "$dest");
    unlink "/tmp/$tmpfile";

    # Update Host internal ip
    $log->info("get subnet <$subnet> and have host ip <$host_ip>");
    my %subnet_hash = $self->{_objs}->{component_dhcpd}->_getEntity()->getSubNet(dhcpd3_subnet_id => $subnet);

    my $ipv4_internal_id
        = $self->{_objs}->{host}->setInternalIP(ipv4_address => $host_ip,
                                                ipv4_mask    => $subnet_hash{'dhcpd3_subnet_mask'});
}

sub _generateKanopyaHalt{
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "etc_path", "targetname" ]);

    my $rand = new String::Random;
    my $template = Template->new($config);
    my $tmpfile = $rand->randpattern("cccccccc");
    my $tmpfile2 = $rand->randpattern("cccccccc");
    my $input = "KanopyaHalt.tt";
    my $omitted_file = "Kanopya_omitted_iscsid";

    #TODO: mettre en parametre le port du iscsi du nas!!
    my $vars = {
        target   => $args{targetname},
        nas_ip   => $self->{_objs}->{container_access}->getAttr(name => 'container_access_ip'),
        nas_port => $self->{_objs}->{container_access}->getAttr(name => 'container_access_port'),
    };

    my $components = $self->{_objs}->{components};
    foreach my $i (keys %$components) {
        # TODO: Check if it is an ExportClient and call generic method
        if ($components->{$i}->isa("Entity::Component")) {
            if ($components->{$i}->isa("Entity::Component::Openiscsi2")) {
                $log->debug("The cluster component is an Openiscsi2");

                my $iscsi_export = $components->{$i};
                $vars->{data_exports} = $iscsi_export->getExports();
            }
        }
    }

    $log->debug("Generate Kanopya Halt with :" . Dumper($vars));
    $template->process($input, $vars, "/tmp/" . $tmpfile) or die $template->error(), "\n";

    $self->{executor}->{econtext}->send(src  => "/tmp/$tmpfile",
                                        dest => "$args{etc_path}/init.d/Kanopya_halt");
    unlink "/tmp/$tmpfile";

    $self->{executor}->{econtext}->execute(
        command => "chmod 755 $args{etc_path}/init.d/Kanopya_halt"
    );
    #$self->{executor}->{econtext}->execute(
    #    command => "ln -sf ../init.d/Kanopya_halt $args{etc_path}/rc0.d/S89Kanopya_halt"
    #);

    $log->debug("Generate omitted file <$omitted_file>");
    $self->{executor}->{econtext}->execute(
        command => "cp /templates/internal/$omitted_file /tmp/"
    );
    $self->{executor}->{econtext}->send(
        src  => "/tmp/$omitted_file",
        dest => "$args{etc_path}/init.d/Kanopya_omitted_iscsid"
    );
    unlink "/tmp/$omitted_file";

    $self->{executor}->{econtext}->execute(
        command => "chmod 755 $args{etc_path}/init.d/Kanopya_omitted_iscsid"
    );
    #$self->{executor}->{econtext}->execute(
    #    command => "ln -sf ../init.d/Kanopya_omitted_iscsid " .
    #               "$args{etc_path}/rc0.d/S19Kanopya_omitted_iscsid"
    #);
}

sub _generateNtpdateConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "etc_path" ]);

    my $rand = new String::Random;
    my $tmpfile = $rand->randpattern("cccccccc");
    my $template = Template->new($config);
    my $input = "ntpdate.tt";
    my $data = {
        ntpservers => $self->{bootserver}->{obj}->getMasterNodeIp(),
    };

    $template->process($input, $data, "/tmp/$tmpfile")
        or throw Kanopya::Exception::Internal::IncorrectParam(
                     error => "Error while generating ntpdate configuration ". $template->error() . "\n"
                 );

    $self->{executor}->{econtext}->send(
        src  => "/tmp/$tmpfile",
        dest => "$args{etc_path}/default/ntpdate"
    );

    unlink "/tmp/$tmpfile";
    
    # send ntpdate init script
    $tmpfile = $rand->randpattern("cccccccc");
    $input = "ntpdate";
    $data = {};
    
    $template->process($input, $data, "/tmp/$tmpfile")
        or throw Kanopya::Exception::Internal::IncorrectParam(
                     error => "Error while generating ntpdate init script ". $template->error() . "\n"
                 );

    $self->{executor}->{econtext}->send(
        src  => "/tmp/$tmpfile",
        dest => "$args{etc_path}/init.d/ntpdate"
    );
    
    $self->{executor}->{econtext}->execute(command => "chmod +x $args{etc_path}/init.d/ntpdate");
    $self->{executor}->{econtext}->execute(command => "chroot $args{etc_path}/.. /sbin/insserv -d ntpdate");
    
}

1;

__END__

=pod

=head1 NAME

EOperation::EStartNode - Operation class implementing Node starting operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement Node starting operation

=head1 DESCRIPTION

This operation is the second in node addition in cluster process.
Cluster was prepare during PreStartNode, this operation :
- create the node configuration
- create export if node is diskless
- configure dhcp and node network configuration
- generate information used during node booting process (in the initramfs)
- finally start the node (etherwake, psu or other)

=head1 METHODS

=head2 new

my $op = EOperation::EStartNode->new();

Operation::EStartNode->new creates a new AddMotheboardInCluster operation.
return : EOperation::EStartNode : Operation add host in a cluster

=head2 _init

    $op->_init();
    This private method is used to define some hash in Operation

=head2 _cancel

    Class : Private

    Desc : This private method is used to rollback the operation

=head2 prepare

    Class : Private

    Desc : This private method is used to prepare the operation execution

    Args : internal_cluster : Hash ref : config part of executor config file

=head2 _generateNodeConf

    Class : Private

    Desc : This is the method which call node configuration methods (udev, net...)

    Args : root_dev : Hash ref : This value come from
                                 $cluster->getSystemImage()->getDevices()->{root},
                                 It represents information on root device of cluster's
                                 system image
           etc_targetname   : String : This is the targetname of etc export
           mount_point      : String : This is the node etc disk mount point

=head2 _generateHostnameConf

    Class : Private

    Desc : This file generate file /etc/hostname which contains node host name

    Args : mount_point  : String : path to the directory where is mounted etc of node
           hostname : String : it is the node host name

=head2 _generateInitiatorConf

    Class : Private

    Desc : This file generate file /etc/iscsi/initiatorname.iscsi which contains node initiatorname

    Args : mount_point  : String : path to the directory where is mounted etc of node
           initatorname : String : it is the node initiator name

=head2 _generateUdevConf

    Class : Private

    Desc : This method generates and copies /etc/udev/rules.d/70-persistent-net.rules
           This file defines name of the network interface name with their MAC address

    Args : mount_point  : String : path to the directory where is mounted etc of node

=head2 _generateKanopyaHalt

    Class : Private

    Desc : This script generate and copy KanopyaHalt and iscsi_omitted script on /etc/init.d of node and add them into rc0.d

    Args : mount_point      : String : path to the directory where is mounted etc of node
           etc_targetname   : String : the tagetname of the etc device

=head2 _generateHosts

    Class : Private

    Desc : This method generate and copy hosts file in /etc disk of the node

    Args : mount_point      : String : path to the directory where is mounted etc of node

=head2 _generateNetConf

    Class : Private

    Desc : This method generate and copy network configuration file
           (man /etc/network/interface) file in /etc disk of the node
           It disables iscsi unmount at halt time through deleting rc0.d/S35networking

    Args : mount_point      : String : path to the directory where is mounted etc of node

=head2 _generateBootConf

    Class : Private

    Desc : This method generate the boot configuration file.
           This file contains disk connection specification and system image access method

    Args : root_dev : Hash ref : This value come from
                             $cluster->getSystemImage()->getDevices()->{root},
                             It represents information on root device of cluster's system image
       etc_targetname   : String : This is the targetname of etc export
       initiatorname    : String : This is the node initiator name

=head2 _generateResolvConf

    Class : Private

    Desc : This method generate the file /etc/resolv.conf which is the linux file to define dns server name.

    Args : mount_point  : String : path to the directory where is mounted etc of node

=head2 _generateNtpdateConf

    Class : Private

    Desc : This method generate the file /etc/default/ntpdate which is the config file of ntpdate.
           It allows to synchronize host with time server.

Args : mount_point  : String : path to the directory where is mounted etc of node


=head2 finish

    Class : Public

    Desc : This method is the last execution operation method called.
    It is used to clean and finalize operation execution

    Args :
        None

    Return : Nothing

    Throw

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

Copyright 2011 Hedera Technology SAS
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

