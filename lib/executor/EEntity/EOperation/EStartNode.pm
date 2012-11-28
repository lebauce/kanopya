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

package EEntity::EOperation::EStartNode;
use base "EEntity::EOperation";

use strict;
use warnings;

use String::Random;
use Date::Simple (':all');

use Kanopya::Exceptions;
use EFactory;
use EEntity;
use Entity::ServiceProvider;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Host;
use Entity::Kernel;
use Template;
use General;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

my $config = General::getTemplateConfiguration();


sub check {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => $self->{context}, required => [ "cluster", "host" ]);
}

sub prerequisites {
    my $self  = shift;
    my %args  = @_;
    my $delay = 10;

    my $cluster_id = $self->{context}->{cluster}->id;
    my $host_id    = $self->{context}->{host}->id;

    # Ask to all cluster component if they are ready for node addition.
    my @components = $self->{context}->{cluster}->getComponents(category => "all");
    foreach my $component (@components) {
        my $ready = $component->readyNodeAddition(host_id => $host_id);
        if (not $ready) {
            $log->info("Component $component not ready for node addition");
            return $delay;
        }
    }

    $log->info("Cluster <$cluster_id> ready for node addition");
    return 0;
}

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    # Instanciate the bootserver Cluster
    $self->{context}->{bootserver}
        = EFactory::newEEntity(
              data => Entity->get(id => $self->{config}->{cluster}->{bootserver})
          );

    # Instanciate dhcpd
    my $dhcpd = $self->{context}->{bootserver}->getComponent(name => "Dhcpd", version => 3);
    $self->{context}->{dhcpd_component} = EFactory::newEEntity(data => $dhcpd);

    # Get container of the system image, get the container access of the container
    my $container = $self->{context}->{host}->getNodeSystemimage->getDevice;
    $self->{context}->{container} = EFactory::newEEntity(data => $container);

    # Warning:
    # 1. Systeme image should be activated, so at least one container access exists
    # 2. As systemimages always dedicated for instance, a system image container has
    #    only one container access.
    my $container_access = pop @{ $self->{context}->{container}->getAccesses };
    $self->{context}->{container_access} = EFactory::newEEntity(data => $container_access);

    $self->{context}->{export_manager}
        = EFactory::newEEntity(data => $self->{context}->{container_access}->getExportManager);

    $self->{params}->{kanopya_domainname} = $self->{context}->{bootserver}->cluster_domainname;

    $self->{cluster_components} = $self->{context}->{cluster}->getComponents(category => "all",
                                                                             order_by => "priority");
}

sub execute {
    my $self = shift;

    # Firstly compute the node configuration
    my $mount_options = $self->{context}->{cluster}->cluster_si_shared
                            ? "ro,noatime,nodiratime" : "defaults";

    # Mount the containers on the executor.
    my $mountpoint = $self->{context}->{container}->getMountPoint;

    $log->debug('Mounting the container <' . $mountpoint . '>');
    $self->{context}->{container_access}->mount(mountpoint => $mountpoint,
                                                econtext   => $self->getEContext,
                                                erollback  => $self->{erollback});

    my $is_loadbalanced = $self->{context}->{cluster}->isLoadBalanced;
    my $is_masternode = $self->{context}->{cluster}->getCurrentNodesCount == 0;

    $log->info("Generate network configuration");
    IFACE:
    foreach my $iface (@{ $self->{context}->{host}->getIfaces }) {
        # Handle associated ifaces only
        if ($iface->netconfs) {
            # Public network on loadbalanced cluster must be configured only
            # on the master node
            if ($iface->hasRole(role => 'public') and $is_loadbalanced and not $is_masternode) {
                next IFACE;
            }

            # Assign ip from the associated interface poolip
            $iface->assignIp();

            # Apply VLAN's
            my $ehost_manager = EFactory::newEEntity(data => $self->{context}->{host}->getHostManager);
            for my $netconf ($iface->netconfs) {
                for my $vlan ($netconf->vlans) {
                    $log->info("Apply VLAN on " . $iface->iface_name);
                    $ehost_manager->applyVLAN(iface => $iface, vlan => $vlan);
                }
            }
        }
    }

    $log->info("Operate components configuration");
    foreach my $component (@{ $self->{cluster_components} }) {
        my $ecomponent = EFactory::newEEntity(data => $component);
        $ecomponent->addNode(host               => $self->{context}->{host},
                             mount_point        => $mountpoint,
                             cluster            => $self->{context}->{cluster},
                             container_access   => $self->{context}->{container_access},
                             erollback          => $self->{erollback});
    }

    $log->info("Operate Boot Configuration");
    $self->_generateBootConf(mount_point => $mountpoint,
                             filesystem => $self->{context}->{container}->container_filesystem,
                             options    => $mount_options);

    # Authorize the Kanopya master to connect to the node using SSH
    my $rsapubkey_cmd = "mkdir -p $mountpoint/root/.ssh ; " .
                        "cat /root/.ssh/kanopya_rsa.pub > $mountpoint/root/.ssh/authorized_keys";
    $self->getExecutorEContext->execute(command => $rsapubkey_cmd);

    # Update kanopya etc hosts
    my @data = ();
    for my $host (Entity::Host->getHosts(hash => {})) {
        my $hostname = $host->host_hostname;
        next if (not $hostname or $hostname eq '');
        push @data, {
            ip         => $host->adminIp,
            hostname   => $hostname,
            domainname => $self->{params}->{kanopya_domainname},
        };
    }

    my $template = Template->new( {
        INCLUDE_PATH => '/templates/components/linux',
        INTERPOLATE  => 0,
        POST_CHOMP   => 0,
        EVAL_PERL    => 1,
        RELATIVE     => 1,
    } );

    $template->process('hosts.tt', { hosts => \@data }, '/etc/hosts');

    # Umount system image container
    $self->{context}->{container_access}->umount(mountpoint => $mountpoint,
                                                 econtext   => $self->getEContext,
                                                 erollback  => $self->{erollback});

    # Create node instance
    $self->{context}->{host}->setNodeState(state => "goingin");
    $self->{context}->{host}->save();

    # Finally we start the node
    $self->{context}->{host} = $self->{context}->{host}->start(
        erollback  => $self->{erollback},
        hypervisor => $self->{context}->{hypervisor}, #only need for vm add
    );
}

sub _cancel {
    my $self = shift;

    $log->info("Cancel start node, we will try to remove node link for <" .
               $self->{context}->{host}->id . ">");

    $self->{context}->{host}->stopToBeNode();

    my $hosts = $self->{context}->{cluster}->getHosts();
    if (! scalar keys %$hosts) {
        $self->{context}->{cluster}->setState(state => "down");
    }

    # Try to umount the container.
    eval {
        my $mountpoint = $self->{context}->{container}->getMountPoint;
        $self->{context}->{container_access}->umount(mountpoint => $mountpoint,
                                                     econtext   => $self->getEContext);
    };
}

sub finish {
    my $self = shift;

    # No need to lock the bootserver
    delete $self->{context}->{bootserver};
    delete $self->{context}->{dhcpd_component};
    delete $self->{context}->{container};
    delete $self->{context}->{container_access};
    delete $self->{context}->{export_manager};
    delete $self->{context}->{systemimage};
}

sub _generateBootConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     =>\%args,
                         required => [ 'mount_point', 'filesystem', 'options' ]);

    # Firstly create pxe config file if needed
    my $boot_policy = $self->{context}->{cluster}->cluster_boot_policy;

    if ($boot_policy =~ m/PXE/) {
        $self->_generatePXEConf(cluster     => $self->{context}->{cluster},
                                host        => $self->{context}->{host},
                                mount_point => $args{mount_point});

        if ($boot_policy =~ m/ISCSI/) {
            my $targetname = $self->{context}->{container_access}->container_access_export;
            my $lun_number = $self->{context}->{container_access}->getLunId(host => $self->{context}->{host});
            my $rand = new String::Random;
            my $tmpfile = $rand->randpattern("cccccccc");

            # create Template object
            my $template = Template->new($config);
            my $input = "bootconf.tt";

            my $vars = {
                filesystem    => $self->{context}->{container}->container_filesystem,
                initiatorname => $self->{context}->{host}->host_initiatorname,
                target        => $targetname,
                ip            => $self->{context}->{container_access}->container_access_ip,
                port          => $self->{context}->{container_access}->container_access_port,
                lun           => "lun-" . $lun_number,
                mount_opts    => $args{options},
                mounts_iscsi  => [],
                additional_devices => "",
            };

            eval {
                my $openiscsi = $self->{context}->{cluster}->getComponent(name => "Openiscsi2");
                $vars->{mounts_iscsi} = $openiscsi->getExports();
                    my $tmp = $vars->{mounts_iscsi};
                    foreach my $j (@$tmp){
                        $vars->{additional_devices} .= " ". $j->{name};
                    }
                
            };

            $template->process($input, $vars, "/tmp/$tmpfile")
                or throw Kanopya::Exception::Internal(
                             error => "Error when processing template $input."
                         );

            my $tftp_conf = $self->{config}->{tftp}->{directory};
            my $dest = $tftp_conf . '/' . $self->{context}->{host}->host_hostname . ".conf";

            $self->getEContext->send(src => "/tmp/$tmpfile", dest => "$dest");
            unlink "/tmp/$tmpfile";
        }
    }
}

sub _generatePXEConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     =>\%args,
                         required => ['cluster', 'host', 'mount_point']);

    my $cluster_kernel_id = $args{cluster}->kernel_id;
    my $kernel_id = $cluster_kernel_id ? $cluster_kernel_id : $args{host}->kernel_id;

    my $clustername = $args{cluster}->cluster_name;
    my $hostname = $args{host}->host_hostname;

    my $kernel_version = Entity::Kernel->get(id => $kernel_id)->kernel_version;
    my $boot_policy    = $args{cluster}->cluster_boot_policy;

    my $tftpdir = $self->{config}->{tftp}->{directory};

    my $nfsexport = "";
    if ($boot_policy =~ m/NFS/) {
        $nfsexport = $self->{context}->{container_access}->container_access_export;
    }

    ## Here we create a dedicated initramfs for the node
    
    my $linux_component = EEntity->new(entity => $args{cluster}->getComponent(category => "system"));
    my $initrd_dir = $linux_component->extractInitramfs(src_file => "$tftpdir/initrd_$kernel_version"); 
    
    $linux_component->customizeInitramfs(initrd_dir  => $initrd_dir,
                                         cluster     => $args{cluster},
                                         host        => $args{host},
                                         mount_point => $args{host},
                                        );
                                        
    # create the final storing directory
    my $path = "$tftpdir/$clustername/$hostname";
    my $cmd = "mkdir -p $path";
    $self->getExecutorEContext->execute(command => $cmd);
    my $newinitrd = $path . "/initrd_$kernel_version";

    $linux_component->buildInitramfs(initrd_dir      => $initrd_dir,
                                     compress_type   => 'gzip',
                                     new_initrd_file => $newinitrd
                                    );

    my $gateway  = undef;
    my $pxeiface = $args{host}->getPXEIface;
    if ($args{cluster}->default_gateway ne undef) {
        if ($pxeiface->getPoolip->network->id == $args{cluster}->default_gateway->id) {
            $gateway = $args{cluster}->default_gateway->network_gateway;
        }
    }

    # Add host in the dhcp
    my $subnet = $self->{context}->{dhcpd_component}->getInternalSubNetId();

    # Set Hostname
    my $host_hostname = $self->{context}->{host}->host_hostname;

    # Configure DHCP Component
    my $tmp_kernel_id = $self->{context}->{cluster}->kernel_id;
    my $host_kernel_id = $tmp_kernel_id ? $tmp_kernel_id : $self->{context}->{host}->kernel_id;

    $self->{context}->{dhcpd_component}->addHost(
        dhcpd3_subnet_id                => $subnet,
        dhcpd3_hosts_ipaddr             => $pxeiface->getIPAddr,
        dhcpd3_hosts_mac_address        => $pxeiface->iface_mac_addr,
        dhcpd3_hosts_hostname           => $host_hostname,
        dhcpd3_hosts_ntp_server         => $self->{context}->{bootserver}->getMasterNodeIp(),
        dhcpd3_hosts_domain_name        => $self->{context}->{cluster}->cluster_domainname,
        dhcpd3_hosts_domain_name_server => $self->{context}->{cluster}->cluster_nameserver1,
        dhcpd3_hosts_gateway            => $gateway,
        kernel_id                       => $host_kernel_id,
        erollback                       => $self->{erollback}
    );

    my $eroll_add_dhcp_host = $self->{erollback}->getLastInserted();
    $self->{erollback}->insertNextErollBefore(erollback => $eroll_add_dhcp_host);

    # Generate new configuration file
    $self->{context}->{dhcpd_component}->generate(erollback => $self->{erollback});

    my $eroll_dhcp_generate = $self->{erollback}->getLastInserted();
    $self->{erollback}->insertNextErollBefore(erollback=>$eroll_dhcp_generate);

    # Generate new configuration file
    $self->{context}->{dhcpd_component}->reload(erollback => $self->{erollback});
    $log->info('Kanopya dhcp server reconfigured');

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

    my $node_mac_addr = $pxeiface->iface_mac_addr;
    $node_mac_addr =~ s/:/-/g;
    my $dest = $tftpdir . '/pxelinux.cfg/01-' . lc $node_mac_addr ;

    $self->getEContext->send(src => "/tmp/$tmpfile", dest => "$dest");
    unlink "/tmp/$tmpfile";

    # Update Host internal ip
    $log->debug("Get subnet <$subnet> and have host ip <$pxeiface->getIPAddr>");
    my %subnet_hash = $self->{context}->{dhcpd_component}->getSubNet(dhcpd3_subnet_id => $subnet);
}

1;
