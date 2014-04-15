#    Copyright © 2014 Hedera Technology SAS
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

Execution entity for component KanopyaDeploymentManager.

@since    2014-Apr-9
@instance hash
@self     $self

=end classdoc
=cut

package EEntity::EComponent::EKanopyaDeploymentManager;
use base EEntity::EComponent;

use strict;
use warnings;

use EEntity;

use TryCatch;
use Date::Simple (':all');
use Log::Log4perl "get_logger";
my $log = get_logger("");


=pod
=begin classdoc

Add the host as client for the exported systemimage,
assign network interfaces, configure component on the systemimage,
generate boot configuration and configure dhcp and tftp, and finally start the host

=end classdoc
=cut

sub deployNode {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'node', 'systemimage', 'boot_mode' ],
                         optional => { 'kernel_id'  => undef,
                                       'hypervisor' => undef,
                                       'erollback'  => undef });

    # Here we compute an iscsi initiator name for the node
    my $date = today();
    my $year = $date->year;
    my $month = length($date->month) == 1 ? '0' . $date->month : $date->month;
    $args{node}->host->host_initiatorname("iqn.$year-$month." . $args{node}->node_hostname . ":" . time());

    # For each container accesses of the system image, add the node as export client
    my $options = "rw";
    for my $export (map { EEntity->new(data => $_) } $args{systemimage}->container_accesses) {
        EEntity->new(data => $export->export_manager)->addExportClient(
            export  => $export,
            host    => $args{node}->host,
            options => $options
        );
    }

    $log->info("Assign ips to the node network interfaces");

    $self->_assignNetworkInterfaces(node => $args{node});

    # Use the first systemimage container access found, as all should access to the same container.
    my @accesses = $args{systemimage}->container_accesses;
    my $container_access = EEntity->new(entity => pop @accesses);

    # Mount the containers on the executor.
    my $mountpoint;
    try {
        $log->info("Mounting the container access <" . $container_access->label . ">");
        $mountpoint = $container_access->mount(econtext  => $self->getEContext,
                                               erollback => $args{erollback});
    }
    catch ($err) {
        $log->warn("Unable to mount the container access, continue in configuration less mode.");
    }

    # If the system image is configurable, configure the components
    if ($mountpoint) {
        $log->info("Operate components configuration on mounted systemimage");
        foreach my $component (map { EEntity->new(entity => $_) } $args{node}->components) {
            $component->configureNode(host        => $args{node}->host,
                                      mount_point => $mountpoint,
                                      erollback   => $args{erollback});
        }
    }

    $log->info("Operate Boot Configuration");

    $self->_generateBootConf(node             => $args{node},
                             mount_point      => $mountpoint,
                             container_access => $container_access,
                             boot_mode        => $args{boot_mode},
                             options          => "defaults",
                             kernel_id        => $args{kernel_id},
                             erollback        => $args{erollback});

    # Update boot server /etc/hosts
    my @bootservers = map{ EEntity->new(entity => $_->host) } $self->system_component->getActiveNodes();
    for my $bootserver (@bootservers) {
        EEntity->new(entity => $self->system_component)->generateConfiguration(host => $bootserver);
    }

    # Umount system image container
    if ($mountpoint) {
        $log->info("Unmounting the container access <" . $container_access->label . ">");
        $container_access->umount(econtext => $self->getEContext, erollback => $args{erollback});
    }

    # Apply dhcp and tftp configuration on the deployment server
    for my $component (map { EEntity->new(entity => $_) } ($self->system_component, $self->dhcp_component)) {
        $component->applyConfiguration(tags => [ "kanopya::deployment::deploynode" ])
    }

    # Finally we start the node
    EEntity->new(entity => $args{node}->host)->start(
        hypervisor => $args{hypervisor}, # Required for vm add only
        erollback  => $args{erollback},
    );
}


=pod
=begin classdoc

Remove the host from the dhcp and halt.

=end classdoc
=cut

sub releaseNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'node' ]);

    # Remove Host from the dhcp
    my $dchp = EEntity->new(entity => $self->dhcp_component);
    $dchp->removeHost(host => $args{node}->host);
    $dchp->applyConfiguration();

    # Finaly halt the node
    EEntity->new(entity => $args{node}->host)->halt();
}



=pod
=begin classdoc

Assign ip to the host network interfaces.

=end classdoc
=cut

sub _assignNetworkInterfaces {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'node' ]);

    # Search for any load balanced component on the node
    my $is_loadbalanced = $args{node}->isLoadBalanced;
    # Search for any component master node
    my $is_masternode = (scalar(grep { $_->master_node } $args{node}->component_nodes) > 0);

    IFACE:
    foreach my $iface (@{ $args{node}->host->getIfaces }) {
        # Handle associated ifaces only
        if ($iface->netconfs) {
            # Public network on loadbalanced component node must be configured only
            # on the master node
            if ($iface->hasRole(role => 'public') and $is_loadbalanced and not $is_masternode) {
                $log->info("Skipping interface " . $iface->iface_name);
                next IFACE;
            }

            # Assign ip from the associated interface poolip
            $iface->assignIp();

            # Apply VLAN's
            for my $netconf ($iface->netconfs) {
                for my $vlan ($netconf->vlans) {
                    $log->info("Apply VLAN on " . $iface->iface_name);
                    $args{node}->host->host_manager->applyVLAN(iface => $iface, vlan => $vlan);
                }
            }
        }
        else {
            $log->info("Skipping interface " . $iface->iface_name . ", no associated netconfs");
        }
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
                         required => [ 'node', 'options', 'container_access', 'boot_mode' ],
                         optional => { 'kernel_id' => undef,
                                       'erollback' => undef });

    my $kernel_version = undef;

    # is dedicated initramfs needed for remote root ?
    if ($args{boot_mode} =~ m/(ISCSI|NFS)/) {
        $log->info("Boot policy $args{boot_mode} requires a dedicated initramfs");

        my $kernel_id = $args{kernel_id} ? $args{kernel_id} : $args{node}->host->kernel_id;
        if (not defined $kernel_id) {
            throw Kanopya::Exception::Internal::WrongValue(
                     error => "No kernel defined"
                  );
        }

        $kernel_version = Entity::Kernel->get(id => $kernel_id)->kernel_version;
        if ($args{boot_mode} =~ m/deploy on disk/) {
            my $harddisk;
            try {
                $harddisk = $args{node}->host->findRelated(filters  => [ 'harddisks' ],
                                                           order_by => 'harddisk_device');
                $harddisk->service_provider_id(undef);
            }
            catch ($err) {
                throw Kanopya::Exception::Internal::NotFound(
                    error => "No hard disk to deploy the system on was found"
                );
            }
            $kernel_version = Entity::Kernel->find(hash => { kernel_name => 'deployment' })->kernel_version;
        }

        my $tftpdir = $self->tftp_component->getTftpDirectory;

        $log->info("Extract initramfs $tftpdir/initrd_$kernel_version");

        my $linux_component = EEntity->new(entity => $args{node}->getComponent(category => "System"));
        my $initrd_dir = $linux_component->extractInitramfs(src_file => "$tftpdir/initrd_$kernel_version");

        $log->info("Customize initramfs in $initrd_dir");
        $linux_component->customizeInitramfs(initrd_dir => $initrd_dir,
                                             host       => $args{node}->host);

        # create the final storing directory
        my $path = "$tftpdir/" . $args{node}->node_hostname;
        $self->_host->getEContext->execute(command => "mkdir -p $path");

        $log->info("Build initramfs $path/initrd_$kernel_version");
        $linux_component->buildInitramfs(initrd_dir      => $initrd_dir,
                                         compress_type   => 'gzip',
                                         new_initrd_file => $path . "/initrd_$kernel_version");
    }

    if ($args{boot_mode} =~ m/PXE/) {
        $self->_generatePXEConf(container_access => $args{container_access},
                                node             => $args{node},
                                kernel_id        => $args{kernel_id},
                                kernel_version   => $kernel_version,
                                boot_mode        => $args{boot_mode},
                                erollback        => $args{erollback});

        if ($args{boot_mode} =~ m/ISCSI/) {
            my $targetname = $args{container_access}->container_access_export;
            my $lun_number = $args{container_access}->getLunId(host => $args{node}->host);

            my $vars = {
                initiatorname => $args{node}->host->host_initiatorname,
                target        => $targetname,
                ip            => $args{container_access}->container_access_ip,
                port          => $args{container_access}->container_access_port,
                lun           => "lun-" . $lun_number,
                mount_opts    => $args{options},
                mounts_iscsi  => [],
                additional_devices => "",
            };

            EEntity->new(entity => $self->tftp_component)->generateFile(
                template_dir  => "internal",
                template_file => "bootconf.tt",
                file          => $self->tftp_component->getTftpDirectory .
                                 '/' . $args{node}->host->node->node_hostname . ".conf",
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

    General::checkParams(
        args     =>\%args,
        required => [ 'node', 'container_access', 'boot_mode' ],
        optional => { 'kernel_id' => undef, 'kernel_version' => undef, 'erollback' => undef }
    );

    my $kernel_id = $args{kernel_id} ? $args{kernel_id}: $args{node}->host->kernel_id;
    my $kernel_version = $args{kernel_version} or Entity::Kernel->get(id => $kernel_id)->kernel_version;

    my $nfsexport = "";
    if ($args{boot_mode} =~ m/NFS/) {
        $nfsexport = $args{container_access}->container_access_export;
    }

    # Configure DHCP Component
    EEntity->new(entity => $self->dhcp_component)->addHost(
        host      => $args{node}->host,
        pxe       => 1,
        erollback => $args{erollback}
    );

    my $eroll_add_dhcp_host = $args{erollback}->getLastInserted();
    $args{erollback}->insertNextErollBefore(erollback => $eroll_add_dhcp_host);

    my $eroll_dhcp_generate = $args{erollback}->getLastInserted();
    $args{erollback}->insertNextErollBefore(erollback=>$eroll_dhcp_generate);

    $log->info('Kanopya dhcp server reconfigured');

    # Here we generate pxelinux.cfg for the host
    my $rand    = new String::Random;
    my $tmpfile = $rand->randpattern("cccccccc");

    # create Template object
    my $config   = General::getTemplateConfiguration();
    my $template = Template->new($config);
    my $input    = "node-syslinux.cfg.tt";
    my $pxeiface = $args{node}->host->getPXEIface;

    my $vars = {
        nfsroot    => ($args{boot_mode} =~ m/NFS/) ? 1 : 0,
        iscsiroot  => ($args{boot_mode} =~ m/ISCSI/) ? 1 : 0,
        xenkernel  => ($kernel_version =~ m/xen/) ? 1 : 0,
        kernelfile => "vmlinuz-$kernel_version",
        initrdfile => $args{node}->node_hostname . "/initrd_$kernel_version",
        nfsexport  => $nfsexport,
        iface_name => $pxeiface->iface_name
    };

    $template->process($input, $vars, "/tmp/$tmpfile")
        or throw Kanopya::Exception::Internal(
                     error => "Error when processing template $input."
                 );

    (my $node_mac_addr = $pxeiface->iface_mac_addr) =~ s/:/-/g;
    $self->getEContext->send(
        src => "/tmp/$tmpfile",
        dest => $self->tftp_component->getTftpDirectory . '/pxelinux.cfg/01-' . lc $node_mac_addr
    );
    unlink "/tmp/$tmpfile";
}

1;
