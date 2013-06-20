#    Copyright © 2009-2013 Hedera Technology SAS
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

=pod
=begin classdoc

Configure the system image of the node, and start it.

@since    2012-Aug-20
@instance hash
@self     $self

=end classdoc
=cut

package EEntity::EOperation::EStartNode;
use base "EEntity::EOperation";

use strict;
use warnings;

use String::Random;
use Date::Simple (':all');

use Kanopya::Exceptions;
use EEntity;
use EEntity;
use Entity::ServiceProvider;
use Entity::ServiceProvider::Cluster;
use Entity::Host;
use Entity::Kernel;
use Template;
use General;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

my $config = General::getTemplateConfiguration();


=pod
=begin classdoc

@param cluster the cluster to add node
@param host    the host selected to be registred as node

=end classdoc
=cut

sub check {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => $self->{context}, required => [ "cluster", "host" ]);
}


=pod
=begin classdoc

Ask to the cluster component if they are ready for the node addition.

=end classdoc
=cut

sub prerequisites {
    my $self  = shift;
    my %args  = @_;
    my $delay = 10;

    my $cluster_id = $self->{context}->{cluster}->id;
    my $host_id    = $self->{context}->{host}->id;

    # Ask to all cluster component if they are ready for node addition.
    my @components = $self->{context}->{cluster}->getComponents(category => "all");
    foreach my $component (@components) {
        my $ready = EEntity->new(entity => $component)->readyNodeAddition(host_id => $host_id);
        if (not $ready) {
            $log->info("Component $component not ready for node addition");
            return $delay;
        }
    }

    $log->debug("Cluster <$cluster_id> ready for node addition");
    return 0;
}


=pod
=begin classdoc

Mount the system image on the executor, configure the network, the components,
the boot configuration, and start the node.

=end classdoc
=cut

sub execute {
    my ($self, %args) = @_;
    $self->SUPER::execute(%args);

    # Instanciate the bootserver Cluster
    my $bootserver = EEntity->new(entity => Entity::ServiceProvider::Cluster->getKanopyaCluster);

    # Instanciate tftp server
    my $tftp = EEntity->new(entity => $bootserver->getComponent(category => 'Tftpserver'));

    # Use the first systemimage container access found, as all should access to the same container.
    my @accesses = $self->{context}->{host}->getNodeSystemimage->container_accesses;
    $self->{context}->{container_access} = EEntity->new(entity => pop @accesses);

    # Firstly compute the node configuration
    my $mount_options = $self->{context}->{cluster}->cluster_si_shared
                            ? "ro,noatime,nodiratime" : "defaults";

    # Mount the containers on the executor.
    eval {
        $log->debug("Mounting the container access <$self->{context}->{container_access}>");
        $self->{params}->{mountpoint} = $self->{context}->{container_access}->mount(
                                            econtext  => $self->getEContext,
                                            erollback => $self->{erollback}
                                        );
    };
    if ($@) {
        $log->warn("Unable to mount the container access, continue in configuration less mode.");
    }

    my $is_loadbalanced = $self->{context}->{cluster}->isLoadBalanced;
    my $is_masternode = $self->{context}->{cluster}->getCurrentNodesCount == 1;

    $log->info("Generate network configuration");
    IFACE:
    foreach my $iface (@{ $self->{context}->{host}->getIfaces }) {
        # Handle associated ifaces only
        if ($iface->netconfs) {
            # Public network on loadbalanced cluster must be configured only
            # on the master node
            if ($iface->hasRole(role => 'public') and $is_loadbalanced and not $is_masternode) {
                $log->info("Skipping interface " . $iface->iface_name);
                next IFACE;
            }

            # Assign ip from the associated interface poolip
            $iface->assignIp();

            # Apply VLAN's
            my $ehost_manager = $self->{context}->{host}->getHostManager;
            for my $netconf ($iface->netconfs) {
                for my $vlan ($netconf->vlans) {
                    $log->info("Apply VLAN on " . $iface->iface_name);
                    $ehost_manager->applyVLAN(iface => $iface, vlan => $vlan);
                }
            }
        }
    }

    # If the system image is configurable, configure the components
    if ($self->{params}->{mountpoint}) {
        $log->info("Operate components configuration");
        my @components = $self->{context}->{cluster}->getComponents(category => "all",
                                                                    order_by => "priority");
        foreach my $component (@components) {
            my $ecomponent = EEntity->new(entity => $component);
            $ecomponent->addNode(host             => $self->{context}->{host},
                                 mount_point      => $self->{params}->{mountpoint},
                                 cluster          => $self->{context}->{cluster},
                                 container_access => $self->{context}->{container_access},
                                 erollback        => $self->{erollback});
        }
    }

    $log->info("Operate Boot Configuration");
    $self->_generateBootConf(mount_point => $self->{params}->{mountpoint},
                             options     => $mount_options,
                             tftpserver  => $tftp,
                             bootserver  => $bootserver);

    # Update kanopya etc hosts
    EEntity->new(data => $bootserver->getComponent(category => "System"))->applyConfiguration();

    # Umount system image container
    if ($self->{params}->{mountpoint}) {
        $self->{context}->{container_access}->umount(econtext   => $self->getEContext,
                                                     erollback  => $self->{erollback});
    }

    # Finally we start the node
    $self->{context}->{host} = $self->{context}->{host}->start(
                                   erollback  => $self->{erollback},
                                   hypervisor => $self->{context}->{hypervisor}, # Required for vm add only
                                   cluster    => $self->{context}->{cluster}
                               );

    eval { $self->{params}->{vminfo} = $self->{context}->{host}->getVmInfo(); };
}


=pod
=begin classdoc

Update the node state.

=end classdoc
=cut

sub finish {
    my ($self, %args) = @_;
    $self->SUPER::finish(%args);

    $self->{context}->{host}->setNodeState(state => "goingin");

    delete $self->{context}->{systemimage};
}


=pod
=begin classdoc

Generate the boot configuration.

=end classdoc
=cut

sub _generateBootConf {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'options', 'tftpserver', 'bootserver' ],
                         optional => { 'mount_point' => undef });

    my $cluster     = $self->{context}->{cluster};
    my $host        = $self->{context}->{host};
    my $boot_policy = $cluster->cluster_boot_policy;
    my $tftpdir     = $args{tftpserver}->getTftpDirectory;
    my $kernel_version = undef;

    # is dedicated initramfs needed for remote root ?
    if ($boot_policy =~ m/(ISCSI|NFS)/) {
        $log->info("Boot policy $boot_policy requires a dedicated initramfs");

        my $kernel_id   = $cluster->kernel_id ? $cluster->kernel_id : $host->kernel_id;
        my $clustername = $cluster->cluster_name;
        my $hostname    = $host->node->node_hostname;

        if (not defined $kernel_id) {
            throw Kanopya::Exception::Internal::WrongValue(
                     error => "Neither cluster nor host kernel defined"
                  );
        }
        my $host_params = $cluster->getManagerParameters(manager_type => 'HostManager');
        $kernel_version = Entity::Kernel->get(id => $kernel_id)->kernel_version;
        if ($host_params->{deploy_on_disk}) {
            my $harddisk;
            eval {
                $harddisk = $host->findRelated(
                    filters  => [ 'harddisks' ],
                    order_by => 'harddisk_device'
                );
            };
            if ($@) {
                throw Kanopya::Exception::Internal::NotFound(
                    error => "No hard disk to deploy the system on was found"
                );
            }
            if ($harddisk->service_provider_id != $cluster->id) {
                $kernel_version = Entity::Kernel->find(hash => { kernel_name => 'deployment' })->kernel_version;
            }
            else {
                return;
            }
        }

        my $linux_component = EEntity->new(entity => $cluster->getComponent(category => "System"));
        
        $log->info("Extract initramfs $tftpdir/initrd_$kernel_version");

        my $initrd_dir = $linux_component->extractInitramfs(src_file => "$tftpdir/initrd_$kernel_version"); 
        $log->info("Customize initramfs in $initrd_dir");
        $linux_component->customizeInitramfs(initrd_dir => $initrd_dir,
                                             cluster    => $cluster,
                                             host       => $host);

        # create the final storing directory
        my $path = "$tftpdir/$clustername/$hostname";
        my $cmd = "mkdir -p $path";
        $self->_host->getEContext->execute(command => $cmd);
        my $newinitrd = $path . "/initrd_$kernel_version";

        $log->info("Build initramfs $newinitrd");
        $linux_component->buildInitramfs(initrd_dir      => $initrd_dir,
                                         compress_type   => 'gzip',
                                         new_initrd_file => $newinitrd);
    }

    if ($boot_policy =~ m/PXE/) {
        $self->_generatePXEConf(cluster        => $self->{context}->{cluster},
                                host           => $self->{context}->{host},
                                mount_point    => $args{mount_point},
                                kernel_version => $kernel_version,
                                tftpserver     => $args{tftpserver},
                                bootserver     => $args{bootserver});

        if ($boot_policy =~ m/ISCSI/) {
            my $targetname = $self->{context}->{container_access}->container_access_export;
            my $lun_number = $self->{context}->{container_access}->getLunId(host => $self->{context}->{host});
            my $rand = new String::Random;
            my $tmpfile = $rand->randpattern("cccccccc");

            # create Template object
            my $template = Template->new($config);
            my $input = "bootconf.tt";

            my $vars = {
                initiatorname => $self->{context}->{host}->host_initiatorname,
                target        => $targetname,
                ip            => $self->{context}->{container_access}->container_access_ip,
                port          => $self->{context}->{container_access}->container_access_port,
                lun           => "lun-" . $lun_number,
                mount_opts    => $args{options},
                mounts_iscsi  => [],
                additional_devices => "",
            };

            $template->process($input, $vars, "/tmp/$tmpfile")
                or throw Kanopya::Exception::Internal(
                             error => "Error when processing template $input."
                         );

            my $tftp_conf = $args{tftpserver}->getTftpDirectory;
            my $dest = $tftp_conf . '/' . $self->{context}->{host}->node->node_hostname . ".conf";

            $self->getEContext->send(src => "/tmp/$tmpfile", dest => "$dest");
            unlink "/tmp/$tmpfile";
        }
    }
}


=pod
=begin classdoc

Generate the PXE configuration.

=end classdoc
=cut

sub _generatePXEConf {
    my ($self, %args) = @_;

    General::checkParams(args     =>\%args,
                         required => [ 'cluster', 'host', 'bootserver', 'tftpserver' ],
                         optional => { 'mount_point'    => undef,
                                       'kernel_version' => undef });

    # Instanciate dhcpd
    my $dhcpd = EEntity->new(entity => $args{bootserver}->getComponent(category => "Dhcpserver"));

    my $cluster_kernel_id = $args{cluster}->kernel_id;
    my $kernel_id = $cluster_kernel_id ? $cluster_kernel_id : $args{host}->kernel_id;

    my $clustername = $args{cluster}->cluster_name;
    my $hostname = $args{host}->node->node_hostname;

    my $kernel_version = $args{kernel_version} or Entity::Kernel->get(id => $kernel_id)->kernel_version;
    my $boot_policy    = $args{cluster}->cluster_boot_policy;

    my $tftpdir = $args{tftpserver}->getTftpDirectory;

    my $nfsexport = "";
    if ($boot_policy =~ m/NFS/) {
        $nfsexport = $self->{context}->{container_access}->container_access_export;
    }

    my $gateway  = undef;
    my $pxeiface = $args{host}->getPXEIface;
    if (defined $args{cluster}->default_gateway) {
        if ($pxeiface->getPoolip->network->id == $args{cluster}->default_gateway->id) {
            $gateway = $args{cluster}->default_gateway->network_gateway;
        }
    }

    # Add host in the dhcp
    my $subnet = $dhcpd->getInternalSubNetId();

    # Configure DHCP Component
    my $tmp_kernel_id = $self->{context}->{cluster}->kernel_id;
    my $host_kernel_id = $tmp_kernel_id ? $tmp_kernel_id : $self->{context}->{host}->kernel_id;

    my $ntpserver = $args{bootserver}->getComponent(category => 'System');
    $dhcpd->addHost(
        dhcpd3_subnet_id                => $subnet,
        dhcpd3_hosts_ipaddr             => $pxeiface->getIPAddr,
        dhcpd3_hosts_mac_address        => $pxeiface->iface_mac_addr,
        dhcpd3_hosts_hostname           => $hostname,
        # While we do not have a ntp or bootserver component, use the system component on kanopya master
        dhcpd3_hosts_ntp_server         => $ntpserver->getMasterNode->adminIp,
        dhcpd3_hosts_domain_name        => $self->{context}->{cluster}->cluster_domainname,
        dhcpd3_hosts_domain_name_server => $self->{context}->{cluster}->cluster_nameserver1,
        dhcpd3_hosts_gateway            => $gateway,
        kernel_id                       => $host_kernel_id,
        erollback                       => $self->{erollback}
    );

    my $eroll_add_dhcp_host = $self->{erollback}->getLastInserted();
    $self->{erollback}->insertNextErollBefore(erollback => $eroll_add_dhcp_host);

    # Generate new configuration file
    $dhcpd->generate(erollback => $self->{erollback});

    my $eroll_dhcp_generate = $self->{erollback}->getLastInserted();
    $self->{erollback}->insertNextErollBefore(erollback=>$eroll_dhcp_generate);

    # Generate new configuration file
    $dhcpd->reload(erollback => $self->{erollback});
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
    my %subnet_hash = $dhcpd->getSubNet(dhcpd3_subnet_id => $subnet);
}

sub cancel {
    my ($self, %args) = @_;

     $log->debug(Dumper $self->{params}->{vminfo});

    if (defined $self->{context}->{host}) {
        if ($self->{context}->{host}->isa('EEntity::EHost::EVirtualMachine')) {
            eval {
                $self->{context}->{host}->getHostManager->promoteVm(
                    host => $self->{context}->{host}->_entity,
                    %{$self->{params}->{vminfo}}
                );
            }
        }

        eval {
            $self->{context}->{host}->reload->halt();
        };
        if ($@) {
            $log->warn($@);
        }
        eval {
            $self->{context}->{host}->reload->stop();
        };
        if ($@) {
            $log->warn($@);
        }
    }
}
1;
