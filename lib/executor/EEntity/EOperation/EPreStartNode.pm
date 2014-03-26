#    Copyright © 2011 Hedera Technology SAS
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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod
=begin classdoc

Register the new node.

@since    2012-Aug-20
@instance hash
@self     $self

=end classdoc
=cut

package EEntity::EOperation::EPreStartNode;
use base "EEntity::EOperation";

use strict;
use warnings;

use Kanopya::Exceptions;
use EEntity;
use Entity::Host;

use Log::Log4perl "get_logger";
use Data::Dumper;
use String::Random;
use Date::Simple (':all');
use Template;
use String::Random;

my $log = get_logger("");
my $errmsg;


=pod
=begin classdoc

@param cluster     the cluster to add node
@param host        the host selected to be registred as node
@param systemimage the system image of the node
@param node_number the number of the new node

=end classdoc
=cut

sub check {
    my ($self, %args) = @_;

    General::checkParams(args => $self->{context}, required => [ "cluster", "host", "systemimage" ]);

    General::checkParams(args => $self->{params}, required => [ "node_number" ]);
}


=pod
=begin classdoc

Register the node.

=end classdoc
=cut

sub execute {
    my ($self, %args) = @_;

    my @components = $self->{context}->{cluster}->getComponents(category => "all",
                                                                order_by => "priority");

    foreach my $component (@components) {
        EEntity->new(data => $component)->preStartNode(
            host    => $self->{context}->{host},
            cluster => $self->{context}->{cluster},
        );
    }

    # Define a hostname
    my $hostname = $self->{context}->{cluster}->cluster_basehostname;
    if ($self->{context}->{cluster}->cluster_max_node > 1) {
        $hostname .=  $self->{params}->{node_number};
    }

    # Register the node in the cluster
    my $params = { host        => $self->{context}->{host},
                   systemimage => $self->{context}->{systemimage},
                   number      => $self->{params}->{node_number},
                   hostname    => $hostname };

    # If components to install on the node defined,
    if ($self->{params}->{component_types}) {
        $params->{components} = $self->{context}->{cluster}->searchRelated(
                                    filters => [ 'components' ],
                                    hash    => {
                                        'component_type.component_type_id' => $self->{params}->{component_types}
                                    }
                                );
    }
    $self->{context}->{cluster}->registerNode(%$params);

    # Create the node working directory where generated files will be
    # stored.
    my $dir = $self->_executor->getConf->{clusters_directory};
    $dir .= '/' . $self->{context}->{cluster}->cluster_name;
    $dir .= '/' . $hostname;
    $self->getEContext->execute(command => "mkdir -p $dir");

    # Here we compute an iscsi initiator name for the node
    my $date = today();
    my $year = $date->year;
    my $month = $date->month;
    if (length($month) == 1) {
        $month = '0' . $month;
    }

    my $initiatorname = 'iqn.' . $year . '-' . $month . '.';
    $initiatorname .= $self->{context}->{cluster}->cluster_name;
    $initiatorname .= '.' . $self->{context}->{host}->node->node_hostname;
    $initiatorname .= ':' . time();

    $self->{context}->{host}->setAttr(name  => 'host_initiatorname',
                                      value => $initiatorname,
                                      save  => 1);

    # For each container accesses of the system image, add an export client
    my $options = "rw";
    for my $container_access ($self->{context}->{systemimage}->container_accesses) {
        my $export_manager = EEntity->new(data => $container_access->getExportManager);
        my $export         = EEntity->new(data => $container_access);

        $export_manager->addExportClient(
            export  => $export,
            host    => $self->{context}->{host},
            options => $options
        );
    }

    # Use the first systemimage container access found, as all should access to the same container.
    my @accesses = $self->{context}->{host}->getNodeSystemimage->container_accesses;
    $self->{context}->{container_access} = EEntity->new(entity => pop @accesses);

    # Firstly compute the node configuration
    my $mount_options = "defaults";

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

    # Instanciate the bootserver Cluster
    my $bootserver = EEntity->new(entity => Entity::ServiceProvider::Cluster->getKanopyaCluster);

    # Instanciate tftp server
    my $tftp = EEntity->new(entity => $bootserver->getComponent(category => 'Tftpserver'));

    $self->_generateBootConf(mount_point => $self->{params}->{mountpoint},
                             options     => $mount_options,
                             tftpserver  => $tftp,
                             bootserver  => $bootserver);

    # Update kanopya etc hosts
    my $kanopya = Entity::ServiceProvider::Cluster->getKanopyaCluster;
    my $system = EEntity->new(entity => $kanopya->getComponent(category => "System"));

    for my $executor ($system->getActiveNodes()) {
        $system->generateConfiguration(
            host    => EEntity->new(entity => $executor->host),
            cluster => EEntity->new(entity => $kanopya)
        );
    }

    # Umount system image container
    if ($self->{params}->{mountpoint}) {
        $self->{context}->{container_access}->umount(econtext   => $self->getEContext,
                                                     erollback  => $self->{erollback});
    }
}


=pod
=begin classdoc

Generate the boot configuration.

=end classdoc
=cut

sub _generateBootConf {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'options', 'tftpserver', 'bootserver' ]);

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
            else {
                $harddisk->service_provider_id(undef);
            }
            $kernel_version = Entity::Kernel->find(hash => { kernel_name => 'deployment' })->kernel_version;
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
                                kernel_version => $kernel_version,
                                tftpserver     => $args{tftpserver},
                                bootserver     => $args{bootserver});

        if ($boot_policy =~ m/ISCSI/) {
            my $targetname = $self->{context}->{container_access}->container_access_export;
            my $lun_number = $self->{context}->{container_access}->getLunId(host => $self->{context}->{host});

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

            $args{tftpserver}->generateFile(
                template_dir  => "internal",
                template_file => "bootconf.tt",
                file          => $args{tftpserver}->getTftpDirectory .
                                 '/' . $self->{context}->{host}->node->node_hostname . ".conf",
                data          => $vars,
                mode          => 755
            );
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
                         optional => { 'kernel_version' => undef });

    # Instanciate dhcpd
    my $dhcpd = $args{bootserver}->getComponent(category => "Dhcpserver");

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

    # Configure DHCP Component
    $dhcpd->addHost(host      => $self->{context}->{host},
                    pxe       => 1,
                    erollback => $self->{erollback});

    my $eroll_add_dhcp_host = $self->{erollback}->getLastInserted();
    $self->{erollback}->insertNextErollBefore(erollback => $eroll_add_dhcp_host);

    my $eroll_dhcp_generate = $self->{erollback}->getLastInserted();
    $self->{erollback}->insertNextErollBefore(erollback=>$eroll_dhcp_generate);

    $log->info('Kanopya dhcp server reconfigured');

    # Here we generate pxelinux.cfg for the host
    my $rand    = new String::Random;
    my $tmpfile = $rand->randpattern("cccccccc");

    # create Template object
    my $config   = General::getTemplateConfiguration();
    my $template = Template->new($config);
    my $input    = "node-syslinux.cfg.tt";
    my $pxeiface = $self->{context}->{host}->getPXEIface;

    my $vars = {
        nfsroot    => ($boot_policy =~ m/NFS/) ? 1 : 0,
        iscsiroot  => ($boot_policy =~ m/ISCSI/) ? 1 : 0,
        xenkernel  => ($kernel_version =~ m/xen/) ? 1 : 0,
        kernelfile => "vmlinuz-$kernel_version",
        initrdfile => "$clustername/$hostname/initrd_$kernel_version",
        nfsexport  => $nfsexport,
        iface_name => $pxeiface->iface_name
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
}


=pod
=begin classdoc

Update the node state.

=end classdoc
=cut

sub finish {
    my ($self, %args) = @_;

    $self->{context}->{host}->setNodeState(state => "pregoingin");
}


=pod
=begin classdoc

Unregister the node.

=end classdoc
=cut

sub cancel {
    my ($self, %args) = @_;

    if (defined $self->{context}->{host}->node) {
        my $dir = $self->_executor->getConf->{clusters_directory};
        $dir .= '/' . $self->{context}->{cluster}->cluster_name;
        $dir .= '/' . $self->{context}->{host}->node->node_hostname;
        $self->getEContext->execute(command => "rm -r $dir");

        $self->{context}->{cluster}->unregisterNode(node => $self->{context}->{host}->node);
    }
}

1;
