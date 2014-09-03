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
use parent EEntity::EComponent;
use parent EManager;

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
assign network interfaces, configure components on the systemimage,
generate boot configuration and configure dhcp and tftp.

=end classdoc
=cut

sub prepareNode {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'node', 'systemimage', 'boot_policy',
                                       'network_manager', 'boot_manager' ],
                         optional => { 'kernel_id'      => undef,
                                       'deploy_on_disk' => 0,
                                       'hypervisor'     => undef,
                                       'erollback'      => undef });

    # Attach the system image to the node
    # Ask to the storage manager to do this, forward all the managers params
    $args{systemimage}->attach(%args);

    $log->info("Configure network interfaces via network manager " . $args{network_manager}->label);

    # Ask to the network manager to configure the interfaces, forward all the managers params
    $args{network_manager}->configureNetworkInterfaces(%args);

    # Mount the systemimage on the executor.
    my $mountpoint;
    try {
        $log->info("Mounting the system image <" . $args{systemimage}->label . ">");
        $mountpoint = $args{systemimage}->mount(econtext  => $self->getEContext,
                                                erollback => $args{erollback});
    }
    catch ($err) {
        $log->warn("Unable to mount the system image, continue in configuration less mode.");
    }

    # If the system image is configurable, configure the components
    if ($mountpoint) {
        try {
            $log->info("Operate components configuration on mounted systemimage");
            foreach my $component (map { EEntity->new(entity => $_) } $args{node}->components) {
                $log->info("Configuring \"" . $component->label . "\" on node " . $args{node}->label);
                $component->configureNode(host           => $args{node}->host,
                                          mount_point    => $mountpoint,
                                          boot_policy    => $args{boot_policy},
                                          deploy_on_disk => $args{deploy_on_disk},
                                          erollback      => $args{erollback});
            }

            # Umount system image container
            $log->info("Unmounting the system image <" . $args{systemimage}->label . ">");
            $args{systemimage}->umount(econtext => $self->getEContext, erollback => $args{erollback});
        }
        catch ($err) {
            $args{systemimage}->umount(econtext => $self->getEContext, erollback => $args{erollback});
            $err->rethrow();
        }
    }

    $log->info("Operate boot configuration via boot manager " . $args{boot_manager}->label);

    # Ask to the boot manager to configure the boot, forward all the managers params
    $args{boot_manager}->configureBoot(%args);
}


=pod
=begin classdoc

Apply the dhcp configuration on the boot server, and start the host.

=end classdoc
=cut

sub deployNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args,
                         required => [ 'node', 'boot_manager' ],
                         optional => { 'hypervisor'   => undef,
                                       'erollback'    => undef });

    $log->info("Applying boot configuration via boot manager " . $args{boot_manager}->label);

    # Ask to the boot manager to aplly the boot configuration, forward all the managers params
    $args{boot_manager}->applyBootConfiguration(%args);

    # Finally we start the node
    # Implicitly ask to the host manager to start the host, forward all the managers params
    EEntity->new(entity => $args{node}->host)->start(%args);

    $args{node}->setState(state => "goingin");
}


=pod
=begin classdoc

Try to connect to the host, and check availability of the components.

=end classdoc
=cut

sub checkNodeUp {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'node', 'deploy_on_disk' ]);

    # Duration to wait before retrying prerequistes
    my $delay = 10;

    # Duration to wait for setting host broken
    my $broken_time = 240;

    # Check how long the host is 'starting'
    my @state = $args{node}->host->getState;
    my $starting_time = time() - $state[1];
    if ($starting_time > $broken_time) {
        EEntity->new(entity => $args{node}->host)->timeOuted();
    }

    my $node_ip = $args{node}->adminIp;
    if (not $node_ip) {
        throw Kanopya::Exception::Internal(
                  error => "Host \"" . $args{node}->host->label .  "\" has no admin ip."
              );
    }

    if (! EEntity->new(entity => $args{node}->host)->checkUp()) {
        $log->info("Host \"" . $args{node}->host->label . "\" not yet reachable at <$node_ip>");
        return $delay;
    }

    # If deployed on disk, remove the host from the dhcp to avoid the PXE
    # at the next reboot
    if ($args{deploy_on_disk}) {
        # Check if the host has already been deployed
        my $hd = $args{node}->host->find(related  => 'harddisks', order_by => 'harddisk_device');

        if (! (defined $hd->deployed_on_id && $hd->deployed_on_id == $args{node}->id)) {
            # Try connecting to the host, delay if it fails
            try {
                if ($args{node}->getEContext->execute(command => "true")->{exitcode}) {
                    throw Kanopya::Exception::Execution();
                }
            }
            catch ($err) {
                return $delay;
            }

            # Verify hostname
            my $theoricalhostname = $args{node}->node_hostname;
            my $realhostname = $args{node}->getEContext->execute(command => 'hostname -s');

            chomp($realhostname->{stdout});
            if ($theoricalhostname ne $realhostname->{stdout}) {
                throw Kanopya::Exception::Execution::OperationInterrupted(
                    error => "System hostname \"$realhostname->{stdout}\" is different than " .
                             "the database hostname for host \"$theoricalhostname\". " .
                             "Is PXE boot working properly ?"
                );
            }

            # Disable PXE boot but keep the host entry
            $hd->deployed_on_id($args{node}->id);
            my $dhcp = EEntity->new(entity => $self->dhcp_component);
            $dhcp->removeHost(host => $args{node}->host);
            $dhcp->addHost(host => $args{node}->host, pxe => 0);
            $dhcp->applyConfiguration();

            # Now reboot the host
            try {
                $args{node}->getEContext->execute(
                    command => "sync; echo 1 > /proc/sys/kernel/sysrq; echo b > /proc/sysrq-trigger"
                );
            }
            catch ($err) {
                # The ssh connexion is timeouted when the host is rebooted,
                # so the call to execute method fail after the reboot command is executed.
                # Error occured during execution: ssh slave failed: timed out
            }

            return $delay;
        }
    }

    # Check if the component are properly configured
    if (! $args{node}->checkConfiguration()) {
        return $delay;
    }

    # Check if all host components are up.
    if (! $args{node}->checkComponents()) {
        return $delay;
    }

    # Node is up
    $args{node}->host->setState(state => "up");
    $args{node}->setState(state => "in");

    $log->info("Host \"" . $args{node}->host->label .  "\" is 'up'");

    return 0;
}


=pod
=begin classdoc

Remove the host from the dhcp.

=end classdoc
=cut

sub unconfigureNode {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'node', 'boot_manager' ]);

    # Ask to the boot manager to remove the node from the boot system
    $args{boot_manager}->configureBoot(node => $args{node}, remove => 1);
}


=pod
=begin classdoc

Apply the dhcp configuration and halt.

=end classdoc
=cut

sub releaseNode {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'node', 'boot_manager' ]);

    # Ask to the boot manager to remove the node from the boot system
    $args{boot_manager}->applyBootConfiguration(node => $args{node}, remove => 1);

    # Finaly halt the node
    $log->info("Poweroff host " . $args{node}->host->label);
    EEntity->new(entity => $args{node}->host)->halt();

    $args{node}->setState(state => "goingout");
}


=pod
=begin classdoc

Ensure the component do not respond any-more and the host unreachable.

=end classdoc
=cut

sub checkNodeDown {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'node' ]);

    # Duration to wait before retrying prerequistes
    my $delay = 10;

    # Duration to wait for setting host broken
    my $broken_time = 240;

    # Check how long the host is 'stopping'
    my @state = $args{node}->host->getState;
    my $stopping_time = time() - $state[1];

    if($stopping_time > $broken_time) {
        $args{node}->host->setState(state => 'broken');
    }

    # Instanciate an econtext to try initiating an ssh connexion.
    try {
        $args{node}->getEContext;

        # Check if all host components are down.
        my @components = sort { $a->priority <=> $b->priority } $args{node}->components;
        foreach my $component (map { EEntity->new(entity => $_) } @components) {
            $log->debug("Browsing component: " . $component->label);

            if ($component->isUp(node => $args{node})) {
                $log->info("Component " . $component->label . " still up on node " . $args{node}->label);
                return $delay;
            }
            $log->info("Component " . $component->label . " do not respond any more");
        }
    }
    catch (Kanopya::Exception::Network $err) {
        $log->info("Node " . $args{node}->label . " do not repond to ssh any more");
    }
    catch (Kanopya::Exception $err) {
        $err->rethrow();
    }
    catch ($err) {
        throw Kanopya::Exception::Execution(error => $err);
    }

    # Finally ask to the host manager to check if node is still power on
    try {
        if (EEntity->new(entity => $args{node}->host)->checkUp()) {
            $log->info("Node still up, waiting...");
            return $delay;
        }
    }
    catch {
        # Check test failed, considering the host down
    }

    # Stop the host
    EEntity->new(entity => $args{node}->host)->stop();

    return 0;
}


=pod
=begin classdoc

Ensure the component do not respond any-more and the host unreachable.

=end classdoc
=cut

sub cancelPrepareNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'node', 'boot_manager' ]);

    $self->unconfigureNode(node => $args{node}, boot_manager => $args{boot_manager});
    EEntity->new(entity => $self->dhcp_component)->applyConfiguration();
}


=pod
=begin classdoc

Set the boot configuration on the boot server in function of the boot_policy.

=end classdoc
=cut

sub configureBoot {
    my ($self, %args) = @_;

    General::checkParams(args     =>\%args,
                         required => [ 'node' ],
                         optional => { 'kernel_id' => undef, 'erollback' => undef, 'remove' => 0 });

    if ($args{remove}) {
        # Remove Host from the dhcp
        try {
            EEntity->new(entity => $self->dhcp_component)->removeHost(host => $args{node}->host);
        }
        catch (Kanopya::Exception::Internal::NotFound $err) {
            $log->warn("Node " . $args{node}->node_hostname . " not found in dhcpd hosts")
        }
        catch ($err) {
            $err->rethrow();
        }
        return;
    }

    General::checkParams(args     =>\%args,
                         required => [ 'systemimage', 'boot_policy', 'deploy_on_disk' ]);

    # Check for unsuported system image type
    if (ref($args{systemimage}) ne "EEntity::ESystemimage") {
        throw Kanopya::Exception::Internal::Inconsistency(
                  error => "Unsuported image type " . ref($args{systemimage}) .
                           " for boot manager " . $self->label
              )
    }

    my @accesses = $args{systemimage}->container_accesses;
    $self->_generateBootConf(node             => $args{node},
                             container_access => EEntity->new(entity => pop(@accesses)),
                             boot_policy      => $args{boot_policy},
                             deploy_on_disk   => $args{deploy_on_disk},
                             kernel_id        => $args{kernel_id},
                             erollback        => $args{erollback});

    # Update boot server /etc/hosts
    my @bootservers = map{ EEntity->new(entity => $_->host) } @{ $self->system_component->getActiveNodes() };
    for my $bootserver (@bootservers) {
        EEntity->new(entity => $self->system_component)->generateConfiguration(host => $bootserver);
    }
}


=pod
=begin classdoc

Workaround for the native HCM boot manager that requires the configuration
of the boot made in 2 steps.

Apply the boot configuration set at configureBoot.

=end classdoc
=cut

sub applyBootConfiguration {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         optional => { 'erollback' => undef, 'remove' => 0 });

    if ($args{remove}) {
        # Apply the dhcpd configuration as the database transction
        # has been commited since the configuration changes at unconfigureNode.
        $log->info("Apply dhcp configuration");
        EEntity->new(entity => $self->dhcp_component)->applyConfiguration();
    }

    # Apply dhcp and tftp configuration on the deployment server
    my @apply = map { EEntity->new(entity => $_) } ($self->system_component, $self->dhcp_component);
    for my $component (@apply) {
        $component->applyConfiguration(tags => [ "kanopya::deployment::deploynode" ])
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
                         required => [ 'node', 'container_access', 'boot_policy', 'deploy_on_disk' ],
                         optional => { 'kernel_id' => undef, 'erollback' => undef });

    my $kernel_version = undef;

    # is dedicated initramfs needed for remote root ?
    if ($args{boot_policy} =~ m/(ISCSI|NFS)/) {
        $log->info("Boot policy $args{boot_policy} requires a dedicated initramfs");

        my $kernel_id = $args{kernel_id} ? $args{kernel_id} : $args{node}->host->kernel_id;
        if (not defined $kernel_id) {
            throw Kanopya::Exception::Internal::WrongValue(
                     error => "No kernel defined"
                  );
        }

        $kernel_version = Entity::Kernel->get(id => $kernel_id)->kernel_version;
        if ($args{deploy_on_disk}) {
            my $harddisk;
            try {
                $harddisk = $args{node}->host->findRelated(filters  => [ 'harddisks' ],
                                                           order_by => 'harddisk_device');
                $harddisk->deployed_on_id(undef);
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

        my $linux_component;
        try {
            $linux_component = EEntity->new(entity => $args{node}->getComponent(category => "System"));
        }
        catch (Kanopya::Exception::Internal::NotFound $err) {
            throw Kanopya::Exception::Internal::NotFound(
                     error => "No \"System\" component found on node <" . $args{node}->label .
                              ">, required to build the initramfs for PXE boot."
                  );
        }
        catch ($err) {
            $err->rethrow();
        }
        my $initrd_dir = $linux_component->extractInitramfs(src_file => "$tftpdir/initrd_$kernel_version");

        $log->info("Customize initramfs in $initrd_dir");
        $linux_component->customizeInitramfs(initrd_dir     => $initrd_dir,
                                             deploy_on_disk => $args{deploy_on_disk},
                                             host           => $args{node}->host);

        # create the final storing directory
        my $path = "$tftpdir/" . $args{node}->node_hostname;
        $self->_host->getEContext->execute(command => "mkdir -p $path");

        $log->info("Build initramfs $path/initrd_$kernel_version");
        $linux_component->buildInitramfs(initrd_dir      => $initrd_dir,
                                         compress_type   => 'gzip',
                                         new_initrd_file => $path . "/initrd_$kernel_version");
    }

    if ($args{boot_policy} =~ m/PXE/) {
        $self->_generatePXEConf(container_access => $args{container_access},
                                node             => $args{node},
                                kernel_id        => $args{kernel_id},
                                kernel_version   => $kernel_version,
                                boot_policy      => $args{boot_policy},
                                erollback        => $args{erollback});

        if ($args{boot_policy} =~ m/ISCSI/) {
            my $targetname = $args{container_access}->container_access_export;
            my $lun_number = $args{container_access}->getLunId(host => $args{node}->host);

            my $vars = {
                initiatorname => $args{node}->host->host_initiatorname,
                target        => $targetname,
                ip            => $args{container_access}->container_access_ip,
                port          => $args{container_access}->container_access_port,
                lun           => "lun-" . $lun_number,
                mount_opts    => "defaults",
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

    General::checkParams(args     =>\%args,
                         required => [ 'node', 'container_access', 'boot_policy' ],
                         optional => { 'kernel_id' => undef, 'kernel_version' => undef });

    my $kernel_id = $args{kernel_id} ? $args{kernel_id}: $args{node}->host->kernel_id;
    my $kernel_version = $args{kernel_version} or Entity::Kernel->get(id => $kernel_id)->kernel_version;

    my $nfsexport = "";
    if ($args{boot_policy} =~ m/NFS/) {
        $nfsexport = $args{container_access}->container_access_export;
    }

    # Configure DHCP Component
    EEntity->new(entity => $self->dhcp_component)->addHost(host      => $args{node}->host,
                                                           pxe       => 1,
                                                           erollback => $args{erollback});

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
        nfsroot    => ($args{boot_policy} =~ m/NFS/) ? 1 : 0,
        iscsiroot  => ($args{boot_policy} =~ m/ISCSI/) ? 1 : 0,
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
