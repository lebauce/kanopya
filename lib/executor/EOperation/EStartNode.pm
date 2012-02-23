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

use Log::Log4perl "get_logger";
use Data::Dumper;
use String::Random;
use Date::Simple (':all');

use Kanopya::Exceptions;
use EFactory;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Host;
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
    RELATIVE     => 1,               # desactive par defaut
};

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new(%args);
    $self->_init();

    return $self;
}

sub _init {
    my $self = shift;
    $self->{executor} = {};
    $self->{bootserver} = {};
    $self->{_objs} = {};
    return;
}

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    General::checkParams(args => \%args, required => ["internal_cluster"]);

    my $params = $self->_getOperation()->getParams();

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

    # Check if a service provider is given in parameters, use default instead.
    eval {
        General::checkParams(args => $params, required => ["storage_provider_id"]);

        $self->{_objs}->{storage_provider}
            = Entity::ServiceProvider->get(id => $params->{storage_provider_id});
    };
    if ($@) {
        $log->info("Service provider id not defined, using default.");
        $self->{_objs}->{storage_provider}
            = Entity::ServiceProvider::Inside::Cluster->get(id => $args{internal_cluster}->{nas});
    }

    # Check if a disk manager is given in parameters, use default instead.
    my $disk_manager;
    eval {
        General::checkParams(args => $params, required => ["disk_manager_id"]);

        $disk_manager
            = $self->{_objs}->{storage_provider}->getManager(id => $params->{disk_manager_id});
    };
    if ($@) {
        $log->info("Disk manager id not defined, using default.");
        eval {
            $disk_manager
                = $self->{_objs}->{storage_provider}->getDefaultManager(category => 'DiskManager');
        };
        if ($@) {
            my $error = $@;
            $errmsg = "Operation DeployComponent failed an error occured :\n$error";
            $log->error($errmsg);
            throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
        }
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

    # Get the disk manager for disk creation, get the export manager for copy from file.
    my $export_manager = $self->{_objs}->{storage_provider}->getDefaultManager(category => 'ExportManager');
    $self->{_objs}->{eexport_manager} = EFactory::newEEntity(data => $export_manager);
    $self->{_objs}->{edisk_manager}   = EFactory::newEEntity(data => $disk_manager);

    # Instanciate tftpd component.
    my $tftp_component = $self->{bootserver}->{obj}->getComponent(name => "Atftpd", version => "0");
    $self->{_objs}->{component_tftpd} = EFactory::newEEntity(data => $tftp_component);

    $log->debug("Load tftpd component (Atftpd version 0.7, it ref is " . ref($self->{_objs}->{component_tftpd}));

    # Instanciate dhcpd component.
    my $dhcp_component = $self->{bootserver}->{obj}->getComponent(name => "Dhcpd", version => "3");
    $self->{_objs}->{component_dhcpd} = EFactory::newEEntity(data => $dhcp_component);

    $log->debug("Load dhcp component (Dhcpd version 3, it ref is " . ref($self->{_objs}->{component_tftpd}));

    # Get contexts
    my $exec_cluster
        = Entity::ServiceProvider::Inside::Cluster->get(id => $args{internal_cluster}->{'executor'});

    my $storage_provider_ip = $self->{_objs}->{storage_provider}->getMasterNodeIp();
    $self->{_objs}->{edisk_manager}->{econtext}
        = EFactory::newEContext(ip_source      => $exec_cluster->getMasterNodeIp(),
                                ip_destination => $storage_provider_ip);
    $self->{_objs}->{eexport_manager}->{econtext}
        = EFactory::newEContext(ip_source      => $exec_cluster->getMasterNodeIp(),
                                ip_destination => $storage_provider_ip);
}

sub _cancel {
    my $self = shift;

    my $params = $self->_getOperation()->getParams();
    my $host = Entity::Host->get(id => $params->{host_id});

    $log->info("Cancel start node, we will try to remove node link for <" .
               $host->getAttr(name => "host_mac_address") . ">");

    $host->stopToBeNode();

    my $cluster = Entity::ServiceProvider::Inside::Cluster->get(id => $params->{cluster_id});
    my $hosts = $cluster->getHosts();
    if (! scalar keys %$hosts) {
        $cluster->setState(state => "down");
    }
}

sub execute {
    my $self = shift;
    my $adm = Administrator->new();
    my $edisk_manager = $self->{_objs}->{edisk_manager};
    my $eexport_manager = $self->{_objs}->{eexport_manager};

    $log->info("Host <" . $self->{_objs}->{host}->getAttr(name => "host_mac_address") . "> etc disk is now created");
    if ((exists $self->{_objs}->{powersupplycard} and defined $self->{_objs}->{powersupplycard}) and
        (exists $self->{_objs}->{powersupplyport_number} and defined $self->{_objs}->{powersupplyport_number})) {
        my $powersupply_id = $self->{_objs}->{powersupplycard}->addPowerSupplyPort(
                                 powersupplyport_number => $self->{_objs}->{powersupplyport_number}
                             );

        $self->{_objs}->{host}->setAttr(name  => 'host_powersupply_id',
                                        value => $powersupply_id);
    }

    my $etc_source_container = $self->{_objs}->{cluster}->getSystemImage->getDevices->{etc};
    my $root_source_container = $self->{_objs}->{cluster}->getSystemImage->getDevices->{root};

    # Creating node etc container
    my $etc_container = $edisk_manager->createDisk(
                            name       => $self->{_objs}->{host}->getEtcName,
                            size       => $etc_source_container->getAttr(name => 'container_size') . "B",
                            filesystem => $etc_source_container->getAttr(name => 'container_filesystem'), ,
                            econtext   => $edisk_manager->{econtext},
                            erollback  => $self->{erollback}
                        );

    $self->{_objs}->{host}->setAttr(name  => 'etc_container_id',
                                    value => $etc_container->getAttr(name => "container_id"));

    # Temporary export the containers to copy contents
    my $source_access = $eexport_manager->createExport(
                            container   => $etc_source_container,
                            export_name => $etc_source_container->getAttr(name => 'container_name'),
                            econtext    => $eexport_manager->{econtext},
                            erollback   => $self->{erollback}
                        );

    my $dest_access = $eexport_manager->createExport(
                          container   => $etc_container,
                          export_name => $etc_container->getAttr(name => 'container_name'),
                          iomode      => "wb",
                          econtext    => $eexport_manager->{econtext},
                          erollback   => $self->{erollback}
                      );

    # Get the corresponding EContainerAccess
    my $esource_access = EFactory::newEEntity(data => $source_access);
    my $edest_access = EFactory::newEEntity(data => $dest_access);

    # Mount the containers on the executor.
    my $source_mountpoint = "/mnt/" . $etc_source_container->getAttr(name => 'container_name');
    my $dest_mountpoint   = "/mnt/" . $etc_container->getAttr(name => 'container_name');

    $log->info('Mounting source container <' . $source_mountpoint . '>');
    $esource_access->mount(mountpoint => $source_mountpoint, econtext => $self->{executor}->{econtext});

    $log->info('Mounting destination container <' . $dest_mountpoint . '>');
    $edest_access->mount(mountpoint => $dest_mountpoint, econtext => $self->{executor}->{econtext});

    # Copy the filesystem.
    my $copy_fs_cmd = "cp -R --preserve=all $source_mountpoint/. $dest_mountpoint/";
    $log->debug($copy_fs_cmd);
    my $cmd_res = $self->{executor}->{econtext}->execute(command => $copy_fs_cmd);

    if ($cmd_res->{'stderr'}){
        $errmsg = "Error with copy of $source_mountpoint to $dest_mountpoint: " .
                  $cmd_res->{'stderr'};
        $log->error($errmsg);
        Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    # Unmount the containers, and remove the temporary exports.
    $esource_access->umount(mountpoint => $source_mountpoint, econtext => $self->{executor}->{econtext});

    $eexport_manager->removeExport(container_access => $source_access,
                                   econtext         => $eexport_manager->{econtext},
                                   erollback        => $self->{erollback});

    # Add host in the dhcp
    my $subnet = $self->{_objs}->{component_dhcpd}->_getEntity()->getInternalSubNetId();
    my $host_ip = $adm->{manager}->{network}->getFreeInternalIP();

    # Set Hostname
    my $host_hostname = $self->{_objs}->{host}->getAttr(name => "host_hostname");
    if (not $host_hostname) {
       
        $host_hostname = $self->{_objs}->{cluster}->getAttr(name => 'cluster_basehostname');
        $host_hostname .=  $self->{_objs}->{host}->getNodeNumber();
   
        $self->{_objs}->{host}->setAttr(
			name => "host_hostname",
            value => $host_hostname
        );                              
    }

    # Set initiatorName
    my $initiator = $eexport_manager->generateInitiatorname(
                        hostname => $self->{_objs}->{host}->getAttr(name=>'host_hostname')
                    );

    $self->{_objs}->{host}->setAttr(name  => "host_initiatorname",
                                    value => $initiator);

    # Configure DHCP Component
    my $host_mac = $self->{_objs}->{host}->getAttr(name => "host_mac_address");
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
        dhcpd3_hosts_mac_address        => $host_mac,
        dhcpd3_hosts_hostname           => $host_hostname,
        dhcpd3_hosts_ntp_server         => $self->{bootserver}->{obj}->getMasterNodeIp(),
        dhcpd3_hosts_domain_name        => $self->{_objs}->{cluster}->getAttr(name => "cluster_domainname"),
        dhcpd3_hosts_domain_name_server => $self->{_objs}->{cluster}->getAttr(name => "cluster_nameserver"),
        kernel_id                       => $host_kernel_id,
        erollback                       => $self->{erollback}
    );

    my $eroll_add_dhcp_host = $self->{erollback}->getLastInserted();
    $self->{erollback}->insertNextErollBefore(erollback=>$eroll_add_dhcp_host);

    # Generate new configuration file
    $self->{_objs}->{component_dhcpd}->generate(econtext    => $self->{bootserver}->{econtext},
                                                erollback   => $self->{erollback});

    my $eroll_dhcp_generate = $self->{erollback}->getLastInserted();
    $self->{erollback}->insertNextErollBefore(erollback=>$eroll_dhcp_generate);

    # Generate new configuration file
    $self->{_objs}->{component_dhcpd}->reload(econtext  => $self->{bootserver}->{econtext},
                                              erollback => $self->{erollback});
    $log->info('Adming dhcp server updated');

    # Update Host internal ip
    $log->info("get subnet <$subnet> and have host ip <$host_ip>");
    my %subnet_hash = $self->{_objs}->{component_dhcpd}->_getEntity()->getSubNet(dhcpd3_subnet_id => $subnet);

    my $ipv4_internal_id
        = $self->{_objs}->{host}->setInternalIP(ipv4_address => $host_ip,
                                                ipv4_mask    => $subnet_hash{'dhcpd3_subnet_mask'});

    # Generate Node configuration
    my $etc_targetname = $eexport_manager->generateTargetname(
                             name => $etc_container->getAttr(name => 'container_name')
                         );

    # TODO: replace by a getAttr on the container_access
    my $root_target_id = $eexport_manager->_getEntity()->getTargetIdLike(
                             iscsitarget1_target_name => '%' . $root_source_container->getAttr(
                                                                   name => 'container_name'
                                                               )
                         );
    # TODO: replace by a getAttr on the container_access
    my $root_targetname = $eexport_manager->_getEntity()->getTargetName(
                              iscsitarget1_target_id => $root_target_id
                          );
    my $root_options = $self->{_objs}->{cluster}->getAttr(name => 'cluster_si_shared')
                           ? "ro,noatime,nodiratime" : "defaults";

    $self->_generateNodeConf(mount_point     => $dest_mountpoint,
                             root_container  => $root_source_container,
                             root_targetname => $root_targetname,
                             root_options    => $root_options,
                             etc_container   => $etc_container,
                             etc_targetname  => $etc_targetname);

    # TODO: Component migration (node, exec context?)
    my $components = $self->{_objs}->{components};
    foreach my $i (keys %$components) {
        my $tmp = EFactory::newEEntity(data => $components->{$i});
        $log->debug("component is " . ref($tmp));
        $tmp->addNode(host          => $self->{_objs}->{host},
                      mount_point   => $dest_mountpoint,
                      cluster       => $self->{_objs}->{cluster},
                      econtext      => $self->{executor}->{econtext},
                      erollback     => $self->{erollback});
    }

    # Umount host etc
    $edest_access->umount(mountpoint => $dest_mountpoint,
                          econtext   => $self->{executor}->{econtext});

    $eexport_manager->removeExport(container_access => $dest_access,
                                   econtext         => $eexport_manager->{econtext},
                                   erollback        => $self->{erollback});

    # Create node instance
    $self->{_objs}->{host}->setNodeState(state => "goingin");
    $self->{_objs}->{host}->save();

    # Generate node etc export
    $eexport_manager->createExport(
        container   => $etc_container,
        export_name => $etc_container->getAttr(name => "container_name"),
        typeio      => "fileio",
        iomode      => "wb",
        econtext    => $eexport_manager->{econtext},
        erollback   => $self->{erollback}
    );

    # Finally we start the node
    my $ehost = EFactory::newEEntity(data => $self->{_objs}->{host});
    $ehost->start(
        econtext  => $self->{executor}->{econtext},
        erollback => $self->{erollback}
    );
}

sub _generateNodeConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args,
                         required => [ "mount_point",
                                       "root_container", "root_targetname", "root_options",
                                       "etc_container", "etc_targetname" ]);

    $log->info("Generate Hostname Conf");
    my $hostname = $self->{_objs}->{host}->getAttr(name => "host_hostname");
    $self->_generateHostnameConf(hostname    => $hostname,
                                 mount_point => $args{mount_point});

    $log->info("Generate Initiator Conf");
    my $initiatorname = $self->{_objs}->{host}->getAttr(name => "host_initiatorname");
    $self->_generateInitiatorConf(initiatorname => $initiatorname,
                                  mount_point   => $args{mount_point});

    $log->info("Generate Udev Conf");
    $self->_generateUdevConf(mount_point => $args{mount_point});

    $log->info("Generate Kanopya Halt script Conf");
    $self->_generateKanopyaHalt(mount_point    => $args{mount_point},
                                etc_targetname => $args{etc_targetname});

    $log->info("Generate Network Conf");
    $self->_generateNetConf(mount_point => $args{mount_point});

    $log->info("Generate resolv.conf");
    $self->_generateResolvConf(mount_point => $args{mount_point});

    # TODO generateRouteConf

    $log->info("Generate Boot Conf");
    $self->_generateBootConf(initiatorname   => $initiatorname,
                             root_container  => $args{root_container},
                             root_targetname => $args{root_targetname},
                             root_options    => $args{root_options},
                             etc_container   => $args{etc_container},
                             etc_targetname  => $args{etc_targetname});

    $log->info("Generate ntpdate Conf");
    $self->_generateNtpdateConf(mount_point => $args{mount_point});
}

sub _generateHostnameConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "mount_point", "hostname" ]);

    $self->{executor}->{econtext}->execute(
        command => "echo $args{hostname} > $args{mount_point}/hostname"
    );
}

sub _generateInitiatorConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "mount_point", "initiatorname" ]);

    $self->{executor}->{econtext}->execute(
        command => "echo \"InitiatorName=$args{initiatorname}\" > " .
                   "$args{mount_point}/iscsi/initiatorname.iscsi"
    );
}

sub _generateUdevConf{
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "mount_point" ]);

    my $rand = new String::Random;
    my $tmpfile = $rand->randpattern("cccccccc");

    # create Template object
    my $template = Template->new($config);
    my $input = "udev_70-persistent-net.rules.tt";

    # TODO: Get ALL the network interfaces
    my $interfaces = [ {
        mac_address   => lc($self->{_objs}->{host}->getAttr(name => "host_mac_address")),
        net_interface => "eth0"
    } ];

    $log->debug("generateUdevConf with " . Dumper($interfaces));
    $template->process($input, { interfaces => $interfaces }, "/tmp/" . $tmpfile)
        or die $template->error(), "\n";

    $self->{executor}->{econtext}->send(
        src => "/tmp/$tmpfile",
        dest => "$args{mount_point}/udev/rules.d/70-persistent-net.rules"
    );
    unlink "/tmp/$tmpfile";
}

sub _generateKanopyaHalt{
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "mount_point", "etc_targetname" ]);

    my $rand = new String::Random;
    my $template = Template->new($config);
    my $tmpfile = $rand->randpattern("cccccccc");
    my $tmpfile2 = $rand->randpattern("cccccccc");
    my $input = "KanopyaHalt.tt";
    my $omitted_file = "Kanopya_omitted_iscsid";

    #TODO: mettre en parametre le port du iscsi du nas!!
    my $vars = {
        etc_target => $args{etc_targetname},
        nas_ip     => $self->{_objs}->{storage_provider}->getMasterNodeIp(),
        nas_port   => "3260"
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
                                        dest => "$args{mount_point}/init.d/Kanopya_halt");
    unlink "/tmp/$tmpfile";

    $self->{executor}->{econtext}->execute(
        command => "chmod 755 $args{mount_point}/init.d/Kanopya_halt"
    );
    $self->{executor}->{econtext}->execute(
        command => "ln -sf ../init.d/Kanopya_halt $args{mount_point}/rc0.d/S89Kanopya_halt"
    );

    $log->debug("Generate omitted file <$omitted_file>");
    $self->{executor}->{econtext}->execute(
        command => "cp /templates/internal/$omitted_file /tmp/"
    );
    $self->{executor}->{econtext}->send(
        src  => "/tmp/$omitted_file",
        dest => "$args{mount_point}/init.d/Kanopya_omitted_iscsid"
    );
    unlink "/tmp/$omitted_file";

    $self->{executor}->{econtext}->execute(
        command => "chmod 755 $args{mount_point}/init.d/Kanopya_omitted_iscsid"
    );
    $self->{executor}->{econtext}->execute(
        command => "ln -sf ../init.d/Kanopya_omitted_iscsid " .
                   "$args{mount_point}/rc0.d/S19Kanopya_omitted_iscsid"
    );
}
sub _generateNetConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'mount_point' ]);

    my $rand = new String::Random;
    my $tmpfile = $rand->randpattern("cccccccc");

    # Create Template object
    my $template = Template->new($config);
    my $input = "network_interfaces.tt";

    # TODO: Get ALL network interface !
    # TODO: Manage virtual IP for master node
    my @interfaces = ();
    my $ip = $self->{_objs}->{host}->getInternalIP();
    my %model = $self->{_objs}->{host}->getModel();

    my $need_bridge = 0;
    my $components = $self->{_objs}->{components};
    while (my ($id, $component) = each %$components) {
        $log->debug(ref($component) . " need_bridge: " . $component->needBridge());
        if ($component->needBridge()) {
            $need_bridge = 1;
            last;
        }
    }

    my $iface = {
        name    => 'eth0',
        address => $ip->{ipv4_internal_address},
        netmask => $ip->{ipv4_internal_mask}
    };

    if($need_bridge) {
        $iface->{name}           = 'br0';
        $iface->{bridge_ports}   = 'eth0';
        $iface->{bridge_stp}     = 'off';
        $iface->{bridge}         = 1;
        $iface->{bridge_fd}      = 2;
        $iface->{bridge_maxwait} = 0;
    }

    push(@interfaces, $iface);

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

    $log->debug(Dumper(@interfaces));
    $template->process($input, { interfaces => \@interfaces }, "/tmp/$tmpfile")
        or throw Kanopya::Exception::Internal::IncorrectParam(
                     error => "Error when generate net conf ". $template->error() . "\n"
                 );

    $self->{executor}->{econtext}->send(
        src => "/tmp/$tmpfile",
        dest => "$args{mount_point}/network/interfaces"
    );
    unlink "/tmp/$tmpfile";

    # Disable network deconfiguration during halt
    unlink "$args{mount_point}/rc0.d/S35networking";
}

sub _generateBootConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     =>\%args,
                         required => [ "root_container", "root_targetname", "root_options",
                                       "etc_container", "etc_targetname",
                                       "initiatorname" ]);

    my $rand = new String::Random;
    my $tmpfile = $rand->randpattern("cccccccc");

    # create Template object
    my $template = Template->new($config);
    my $input = "bootconf.tt";

    my $vars = {
        root_fs            => $args{root_container}->getAttr(name => 'container_filesystem'),
        etc_fs             => $args{etc_container}->getAttr(name => 'container_filesystem'),
        initiatorname      => $args{initiatorname},
        etc_target         => $args{etc_targetname},
        etc_ip             => $self->{_objs}->{storage_provider}->getMasterNodeIp(),
        etc_port           => "3260",
        root_target        => $args{root_targetname},
        root_ip            => $self->{_objs}->{storage_provider}->getMasterNodeIp(),
        root_port          => "3260",
        root_mount_opts    => $args{root_options},
        mounts_iscsi       => [],
        additional_devices => "etc",
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
                     error => "EOperation::EAddHost->GenerateNetConf error when parsing template"
                 );

    my $tftp_conf = $self->{_objs}->{component_tftpd}->_getEntity()->getConf();
    my $dest = $tftp_conf->{'repository'} . '/' . $self->{_objs}->{host}->getAttr(name => "host_hostname") . ".conf";

    $self->{executor}->{econtext}->send(src => "/tmp/$tmpfile", dest => "$dest");
    unlink "/tmp/$tmpfile";
}

sub _generateResolvConf{
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args,
                         required => [ 'mount_point' ]);

    my $rand = new String::Random;
    my $tmpfile = $rand->randpattern("cccccccc");

    my @nameservers = ();

    # TODO: Manage more than only one nameserver !
    push @nameservers, {
        ipaddress => $self->{_objs}->{cluster}->getAttr(name => 'cluster_nameserver')
    };

    my $vars = {
        domainname => $self->{_objs}->{cluster}->getAttr(name => 'cluster_domainname'),
        nameservers => \@nameservers,
    };

    my $template = Template->new($config);
    my $input = "resolv.conf.tt";

    $template->process($input, $vars, "/tmp/".$tmpfile) or die $template->error(), "\n";
    $self->{executor}->{econtext}->send(
        src  => "/tmp/$tmpfile",
        dest => "$args{mount_point}/resolv.conf"
    );
    unlink "/tmp/$tmpfile";
}

sub _generateNtpdateConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "mount_point" ]);

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
        dest => "$args{mount_point}/default/ntpdate"
    );

    unlink "/tmp/$tmpfile";
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

