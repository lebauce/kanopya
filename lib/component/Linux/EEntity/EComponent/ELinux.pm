# Copyright © 2011 Hedera Technology SAS
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

=pod

=begin classdoc

Linux component base class to generate system configuration files.

@since    2012-Jun-10
@instance hash
@self     $self

=end classdoc

=cut

package EEntity::EComponent::ELinux;
use base 'EEntity::EComponent';

use strict;
use warnings;
use File::Basename;
use String::Random;
use POSIX "floor";
use Kanopya::Config;
use Log::Log4perl 'get_logger';
use Data::Dumper;
use Message;
use EEntity;
use Entity::ServiceProvider::Cluster;

my $log = get_logger("");
my $errmsg;

sub getPriority {
    return 20;
}

# generate configuration files on node
sub addNode {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['cluster','host','mount_point']);

    $log->debug("Configuration files generation");
    my $files = $self->generateConfiguration(%args);

    $log->debug("System image preconfiguration");
    $self->preconfigureSystemimage(%args, files => $files);
}

sub postStartNode {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'cluster', 'host' ]);

    my @ehosts = map { EEntity->new(entity => $_) } @{ $args{cluster}->getHosts() };
    for my $ehost (@ehosts) {
        $self->generateConfiguration(
            cluster => $args{cluster},
            host    => $ehost
        );
    }
}

sub postStopNode {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'cluster', 'host' ]);

    my @ehosts = map { EEntity->new(entity => $_) } @{ $args{cluster}->getHosts() };
    for my $ehost (@ehosts) {
        $self->generateConfiguration(
            cluster => $args{cluster},
            host    => $ehost
        );
    }
}

sub isUp {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "cluster", "host" ]);

    my $params = $args{cluster}->getManagerParameters(manager_type => 'HostManager');
    if ($params->{deploy_on_disk}) {
        # Check if the host has already been deployed
        my $harddisk = $args{host}->findRelated(filters  => [ 'harddisks' ],
                                                order_by => 'harddisk_device');
        return 1 if defined $harddisk->service_provider_id && $harddisk->service_provider_id == $args{cluster}->id;

        # Try connecting to the host, return 0 if it fails
        eval { $args{host}->getEContext->execute(command => "true"); };
        return 0 if $@;

        # Disable PXE boot but keep the host entry
        eval {
            $harddisk->service_provider_id($args{cluster}->id);
            my $kanopya = Entity::ServiceProvider::Cluster->getKanopyaCluster;
            my $dhcp    = EEntity->new(data => $kanopya->getComponent(name => "Dhcpd"));
            eval {
                $dhcp->removeHost(host => $args{host});
                $dhcp->addHost(host => $args{host},
                               pxe  => 0);
                $dhcp->applyConfiguration();
            };
            if ($@) {
                throw Kanopya::Exception::Internal::NotFound(
                    error => "No PXE Iface was found"
                );
            }

            # Now reboot the host
            eval {
                $args{host}->getEContext->execute(command => "sync;" .
                                                             "echo 1 > /proc/sys/kernel/sysrq;" .
                                                             "echo b > /proc/sysrq-trigger");
            };
        };
        if ($@) {
            throw Kanopya::Exception::Internal::NotFound(
                error => "No hard disk to deploy the system on was found"
            );
        }
        return 0;
    }

    return 1;
}


=pod
=begin classdoc

Return the available memory amount.
@param host target Host instance

@return hash ref { mem_effectively_available => $free * 1024, mem_total => $total * 1024}

=end classdoc
=cut

sub getAvailableMemory {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    # Get the memory infos from procfs
    my $result = $args{host}->getEContext->execute(command => "cat /proc/meminfo");

    # Keep the lines about free memory only
    my @lines = grep { $_ =~ '^(MemTotal:|MemFree:|Buffers:|Cached:)' } split('\n', $result->{stdout});

    my $total = (split('\s+', shift @lines))[1];

    # Total available memory is the sum of free, buffers and cached memory
    my $free = 0;
    for my $line (@lines) {
        my ($mentype, $amount, $unit) = split('\s+', $line);
        $free += $amount;
    }

    # Return the free memory in bytes
    return {
        mem_effectively_available => $free * 1024,
        mem_total                 => $total * 1024
    }
}


=pod
=begin classdoc

Return the total cpu count.

@param host Target Host instance

@return scalar number of cpus

=end classdoc
=cut

sub getTotalCpu {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    # Get the memory infos from procfs
    my $result = $args{host}->getEContext->execute(command => "cat /proc/cpuinfo");

    # Keep the lines about free memory only
    my @lines = grep { $_ =~ '^processor(\s)+:' } split('\n', $result->{stdout});

    return scalar @lines;
}

# generate all component files for a host

sub generateConfiguration {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'cluster', 'host' ]);

    my $generated_files = [];
    my $kanopya = Entity::ServiceProvider::Cluster->getKanopyaCluster();

    push @$generated_files, $self->_generateHostname(%args);
    push @$generated_files, $self->_generateResolvconf(%args);
    push @$generated_files, $self->_generateUdevPersistentNetRules(%args);
    push @$generated_files, $self->_generateHosts(
                                kanopya_domainname => $kanopya->cluster_domainname,
                                %args
                            );

    return $generated_files;
}

# provision/tweak Systemimage with config files 

sub preconfigureSystemimage {
    my ($self, %args) = @_;
    General::checkParams(args     => \%args,
                         required => [ 'files', 'cluster', 'host', 'mount_point' ]);

    my $econtext = $self->_host->getEContext;

    # send generated files to the image mount directory
    for my $file (@{$args{files}}) {
        $econtext->send(
            src  => $file->{src},
            dest => $args{mount_point} . $file->{dest}
        );
    }

    $self->_generateUserAccount(econtext => $econtext, %args);
    $self->_generateNtpdateConf(econtext => $econtext, %args);
    $self->_generateNetConf(econtext => $econtext, %args);
    $self->_disableRootPassword(econtext => $econtext, %args);

    # Set up fastboot
    $econtext->execute(
        command => "touch $args{mount_point}/fastboot"
    );
}

# individual file generation

=pod

=begin classdoc

Generate the hostname configuration file

@param host Entity::Host instance
@param cluster Entity::ServiceProvider::Cluster instance
@return hashref with src as full path of the generated file, dest as the full path destination

=end classdoc

=cut

sub _generateHostname {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'cluster' ],
                                         optional => { 'path' => '/etc/hostname' });

    my $file = $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/hostname',
        template_dir  => 'components/linux',
        template_file => 'hostname.tt',
        data          => { hostname => $args{host}->node->node_hostname }
    );

    return { src  => $file, dest => $args{path} };
}

sub _generateHosts {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'cluster', 'host', 'kanopya_domainname' ]);

    my @hosts_entries = $args{cluster}->getHostEntries(components => 1);

    my $hosts_tmp = {};
    for my $entry (@hosts_entries) {
        $hosts_tmp->{$entry->{ip}}->{$entry->{fqdn}} = 1;
        for my $alias (@{$entry->{aliases}}) {
            $hosts_tmp->{$entry->{ip}}->{$alias} = 1;
        }
    }

    my @hosts;
    for my $ip (keys $hosts_tmp) {
        push @hosts, {
            ip      => $ip,
            aliases => [keys $hosts_tmp->{$ip}]
        }
    }

    $log->debug('Generate /etc/hosts file');
    my $file = $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/hosts',
        template_dir  => 'components/linux',
        template_file => 'hosts.tt',
        data          => { hosts => \@hosts }
    );

    return { src  => $file, dest => '/etc/hosts' };
}

sub _generateResolvconf {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['cluster','host' ]);

    my @nameservers = ();

    for my $attr ('cluster_nameserver1','cluster_nameserver2') {
        push @nameservers, {
            ipaddress => $args{cluster}->getAttr(name => $attr)
        };
    }

    my $data = {
        domainname => $args{cluster}->getAttr(name => 'cluster_domainname'),
        nameservers => \@nameservers,
    };

    my $file = $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/resolv.conf',
        template_dir  => 'components/linux',
        template_file => 'resolv.conf.tt',
        data          => $data
    );

    return { src  => $file, dest => '/etc/resolv.conf' };
}

sub _generateUdevPersistentNetRules {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host','cluster' ]);

    my @interfaces = ();

    for my $iface ($args{host}->getIfaces()) {
        my $tmp = {
            mac_address   => lc($iface->getAttr(name => 'iface_mac_addr')),
            net_interface => $iface->getAttr(name => 'iface_name')
        };
        push @interfaces, $tmp;
    }

    my $file = $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/udev/rules.d/70-persistent-net.rules',
        template_dir  => 'components/linux',
        template_file => 'udev_70-persistent-net.rules.tt',
        data          => { interfaces => \@interfaces }
    );

    return { src  => $file, dest => '/etc/udev/rules.d/70-persistent-net.rules' };
}

sub _generateUserAccount {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'cluster', 'host', 'mount_point', 'econtext' ]);

    my $econtext = $args{econtext};
    my $user = $args{cluster}->owner;
    my $login = $user->user_login;
    my $password = $user->user_password;

    # create user account and add sudoers entry if necessary
    my $cmd = "cat " . $args{mount_point} . "/etc/passwd | cut -d: -f1 | grep ^$login\$";
    my $result = $econtext->execute(command => $cmd);
    if ($result->{stdout}) {
        $log->info("User account $login already exists");
        Message->send(from => 'Executor', level => 'info',
                      content => "User account $login already exists");
    } else {
        # create the user account
        my $params = " -m -p '$password' $login";
        my $shell = _getShell();
        if (defined $shell) {
            $params .= " -s $shell";
        }
        my $cmd = "chroot " . $args{mount_point} . " useradd $params";
        my $result = $econtext->execute(command => $cmd);

        # add a sudoers file
        $cmd = "umask 227 && echo '$login ALL=(ALL) ALL' > " . $args{mount_point} . "/etc/sudoers.d/$login";
        $result = $econtext->execute(command => $cmd);

        # add ssh pub key
        my $sshkey = $user->getAttr(name => 'user_sshkey');
        if(defined $sshkey) {
            # create ssh directory and authorized_keys file
            my $dir = $args{mount_point} . "/home/$login/.ssh";

            $cmd = "umask 077 && mkdir $dir";
            $result = $econtext->execute(command => $cmd);

            $cmd = "umask 177 && echo '$sshkey' > $dir/authorized_keys";
            $result = $econtext->execute(command => $cmd);

            $cmd = "chroot $args{mount_point} chown -R $login.$login /home/$login/.ssh ";
            $result = $econtext->execute(command => $cmd);
        }
    }
}

sub _getShell() {
    return undef;
}

sub _disableRootPassword {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'cluster', 'host', 'mount_point', 'econtext' ]);
   
    # Disable root password
    my $cmd = 'grep "^root:" ' . $args{mount_point} . '/etc/shadow';
    my $result = $args{econtext}->execute(command => $cmd);
    if ($result->{stdout} =~ m/root:\$/) {
        $cmd = 'chroot ' . $args{mount_point} . ' passwd -dl root';
        $args{econtext}->execute(command => $cmd);
        $log->info('root password deleted');
    }

    # Disable SSH login for root
    $cmd = 'grep "^PermitRootLogin" ' . $args{mount_point} . '/etc/ssh/sshd_config';
    $result = $args{econtext}->execute(command => $cmd);
    if (! ($result->{stdout} =~ m/PermitRootLogin without-password/))  {
        $cmd = 'sed -i "s/PermitRootLogin [a-zA-Z]*/PermitRootLogin without-password/" ' .
                $args{mount_point} . '/etc/ssh/sshd_config';
        $args{econtext}->execute(command => $cmd);
        $log->info('SSH root login without key disabled');
    }

}

sub _generateNtpdateConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'cluster', 'host', 'mount_point', 'econtext' ]);

    # TODO: Implement the ntp component. Use the system component for instance.
    my $ntp = $self->service_provider->getKanopyaCluster->getComponent(category => 'System');
    my $file = $self->generateNodeFile(
                   cluster       => $args{cluster},
                   host          => $args{host},
                   file          => '/etc/default/ntpdate',
                   template_dir  => 'components/linux',
                   template_file => 'ntpdate.tt',
                   data          => { ntpservers => $ntp->getMasterNode->adminIp }
               );

    $args{econtext}->send(
        src  => $file,
        dest => "$args{mount_point}/etc/default/ntpdate"
    );

    # send ntpdate init script
    $file = $self->generateNodeFile(
                cluster       => $args{cluster},
                host          => $args{host},
                file          => '/etc/init.d/ntpdate',
                template_dir  => 'components/linux',
                template_file => 'ntpdate',
                data          => { }
            );

    $args{econtext}->send(
        src  => $file,
        dest => "$args{mount_point}/etc/init.d/ntpdate"
    );

    $args{econtext}->execute(command => "chmod +x $args{mount_point}/etc/init.d/ntpdate");

    $self->service(services    => [ "ntpdate" ],
                   state       => "on",
                   mount_point => $args{mount_point});
}

sub _generateNetConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'cluster', 'host', 'mount_point', 'econtext' ]);

    # search for an potential 'loadbalanced' component
    my $cluster_components = $args{cluster}->getComponents(category => "all");
    my $is_masternode = $args{cluster}->getCurrentNodesCount == 1;
    my $is_loadbalanced = $args{cluster}->isLoadBalanced;

    # Pop an IP adress for all host iface,
    my @net_ifaces;
    IFACES:
    foreach my $iface (@{ $args{host}->getIfaces }) {
        if (not $iface->netconfs) {
            $log->debug("Skipping configuration for non associated iface " . $iface->iface_name);
            next IFACES;
        }

        my ($gateway, $netmask, $ip, $method);

        my $params = $args{cluster}->getManagerParameters(manager_type => 'HostManager');
        if ($params->{deploy_on_disk} && $iface->hasIp) {
            $method = "dhcp";
        }
        elsif ($iface->hasIp) {
            my $network = $iface->getPoolip->network;
            $netmask    = $network->network_netmask;
            $ip         = $iface->getIPAddr;

            if ($is_loadbalanced and not $is_masternode) {
                $gateway = $args{cluster}->getComponent(category => 'LoadBalancer')->getMasterNode->adminIp;
            }
            else {
                $gateway = ($network->id == $args{cluster}->default_gateway_id) ? $network->network_gateway : undef;
            }

            $method = "static";
        }
        else {
            $method = "manual";
        }

        my $net_iface = {
            method    => $method,
            name      => $iface->iface_name,
            address   => $ip,
            netmask   => $netmask,
            gateway   => $gateway,
            iface_pxe => $args{cluster}->cluster_boot_policy ne Manager::HostManager->BOOT_POLICIES->{virtual_disk} ?
                         $iface->iface_pxe : 0
        };

        my @vlans;
        foreach my $netconf ($iface->netconfs) {
            my @netconf_vlans = $netconf->vlans;
            push @vlans, @netconf_vlans;
        }
        if (scalar @vlans > 0) {
           $net_iface->{vlans} = \@vlans;
        }

        #check if iface has slaves (for bonding purposes)
        my @slaves = $iface->slaves;
        if (scalar @slaves > 0) {
            $net_iface->{slaves} = \@slaves;
            $net_iface->{type}   = 'master';
        }

        push @net_ifaces, $net_iface;

        $log->info("Iface " . $iface->iface_name . " configured via static file");
    }

    $self->_writeNetConf(ifaces => \@net_ifaces, %args);
}

=pod

=begin classdoc

extract an existing initrd

@param src_file full path to the initrd file to extract
@return string path to the directory

=end classdoc

=cut

sub extractInitramfs {
    my ($self, %args) = @_;
    General::checkParams(args     =>\%args,
                         required => ['src_file']);

    my $econtext = $self->_host->getEContext;
    my $initrd = $args{src_file};

    my $cmd = "[ -f $args{src_file} ] && echo -n found";
    my $result = $econtext->execute(command => $cmd);
    if($result->{stdout} ne 'found') {
        throw Kanopya::Exception::Internal(
            error => "$initrd not found"
        );
    }

    my $rand = new String::Random;

    # create working directory
    my $initrddir = '/tmp/'.$rand->randpattern("cccccccc");
    $log->info("extract initramfs $initrd to temporary directory $initrddir");
    $cmd = "mkdir -p $initrddir";
    $econtext->execute(command => $cmd);

    # check and retrieve compression type
    $cmd = "file $initrd | grep -o -E '(gzip|bzip2)'";
    $result = $econtext->execute(command => $cmd);
    my $decompress;
    chomp($result->{stdout});
    if($result->{stdout} eq 'gzip') {
        $decompress = 'zcat';
    } elsif($result->{stdout} eq 'bzip2') {
        $decompress = 'bzcat';
    } else {
        throw Kanopya::Exception::Internal(
            error => "Invalid compress type for $initrd ; must be gzip or bzip2"
        );
    }

    # we decompress and extract the original initrd to this directory
    $cmd = "(cd $initrddir && $decompress $initrd | cpio -i)";
    $econtext->execute(command => $cmd);
    return $initrddir;
}

=pod

=begin classdoc

update initrd directory content

@param initrd_dir directory path
@param host Entity::Host instance
@param cluster Entity::ServiceProvider::Cluster instance

=end classdoc

=cut

sub customizeInitramfs {
    my ($self, %args) = @_;

    General::checkParams(args     =>\%args,
                         required => [ 'initrd_dir', 'cluster', 'host' ]);

    my $econtext = $self->_host->getEContext;
    my $initrddir = $args{initrd_dir};
    my $ifaces = $args{host}->getIfaces;
    my $hostname = $args{host}->node->node_hostname;

    my $file = $self->_generateUdevPersistentNetRules(host => $args{host}, cluster => $args{cluster});
    my $udev_rules_dir = dirname($initrddir.$file->{dest});
    my $cmd = 'mkdir -p '.$udev_rules_dir;
    $cmd .= ' && cp '.$file->{src}.' '.$initrddir.$file->{dest};
    $econtext->execute(command => $cmd);

    # TODO check targetname is the same for each container access
    my $portals = [];
    my $target = "";
    for my $container_access ($args{host}->node->systemimage->container_accesses) {
        push @$portals, { ip   => $container_access->container_access_ip,
                          port => $container_access->container_access_port };
        $target = $container_access->container_access_export;
    }

    $log->info("customize initramfs $initrddir");

    my $rootdev = $self->_initrd_iscsi(
                      initrd_dir    => $initrddir,
                      initiatorname => $args{host}->host_initiatorname,
                      target        => $target,
                      portals       => $portals
                  );

    # TODO: Check host harddisks for a harddisk_device called 'autodetect'
    my $host_params = $args{cluster}->getManagerParameters(manager_type => 'HostManager');
    if ($host_params->{deploy_on_disk}) {
        my $harddisk;
        eval {
            $harddisk = $args{host}->findRelated(filters  => [ 'harddisks' ],
                                                 order_by => 'harddisk_device');
        };
        if ($@) {
            throw Kanopya::Exception::Internal::NotFound(
                      error => "No hard disk to deploy the system on was found"
                  );
        }

        my $size = $harddisk->harddisk_size;
        my $device = '/dev/disk/by-path/ip-' . $portals->[0]->{ip} . ':' .
                     $portals->[0]->{port} . '-iscsi-' . $target . '-lun-0';
        
        my $root_size = $size * 0.6 / 1073741824;
        my $swap_size = ($size / 1073741824) - $root_size;

        $self->_initrd_deployment(initrd_dir  => $initrddir,
                                  src_device  => $device,
                                  dest_device => $harddisk->harddisk_device,
                                  root_size   => floor($root_size),
                                  swap_size   => floor($swap_size));
    }
    else {
        # else remove deployement script
        $cmd = 'rm ' . $args{initrd_dir} . '/boot/83-deploy.sh';
        $econtext->execute(command => $cmd);
    }

    my @ifaces = $args{host}->getIfaces();
    $self->_initrd_config(initrd_dir => $initrddir,
                          ifaces     => \@ifaces,
                          hostname   => $args{host}->node->node_hostname,
                          rootdev    => $rootdev);
}

=pod

=begin classdoc

generate config variables for iscsi script in the initrd.
enable multipath script if several portals are provided

@param initrd_dir initrd working directory
@param target device to duplicate to dest_device
@param portals device receiving src_device content
@param initiatorname size in gigabyte to use during root resizing

@return device containing root filesystem

=end classdoc

=cut

sub _initrd_iscsi {
    my ($self, %args) = @_;
    General::checkParams(args     =>\%args,
                         required => ['initrd_dir','target', 'portals', 'initiatorname']);
    my $econtext = $self->_host->getEContext;
    my $cmd;

    # generate send_targets and nodes info

    my $target = $args{target};
    my @portals = @{$args{portals}};

    for my $portal (@portals) {
        my $st_dir = $args{initrd_dir} . '/etc/iscsi/send_targets/' .
                     $portal->{ip} . "," . $portal->{port};

        $cmd = 'mkdir -p ' . $st_dir;
        $econtext->execute(command => $cmd);

        $self->generateFile(
            template_file => 'st_config.tt',
            template_dir  => 'internal/initrd/sles',
            file          => "$st_dir/st_config",
            data          => { port => $portal->{port},
                               ip   => $portal->{ip} }
        );

        my $target_dir = $args{initrd_dir} . "/etc/iscsi/nodes/$target/" .
                         $portal->{ip} . "," . $portal->{port} . ',1';

        $cmd = 'mkdir -p ' . $target_dir;
        $econtext->execute(command => $cmd);

        $self->generateFile(
            template_file => 'default.tt',
            template_dir  => 'internal/initrd/sles',
            file          => "$target_dir/default",
            data          => { target => $target,
                               ip     => $portal->{ip},
                               port   => $portal->{port} }
        );

        $cmd = "echo InitiatorName=$args{initiatorname} > " .
               "$args{initrd_dir}/etc/iscsi/initiatorname.iscsi";

        $econtext->execute(command => $cmd);
    }

    # if you have only one portal, remove multipath capability and use iscsi dev instead of device mapper device
    my $rootdev = '/dev/dm-1';
    if(scalar(@portals) == 1) {
        $log->debug("removing multipath capability");
        $cmd = 'rm '.$args{initrd_dir}.'/boot/04-multipathd.sh '.$args{initrd_dir}.'/boot/21-multipath.sh';
        $econtext->execute(command => $cmd);
        $rootdev = '/dev/disk/by-path/ip-'.$portals[0]->{ip}.':'.$portals[0]->{port}.'-iscsi-'.$target.'-lun-0-part1';
    }
    return $rootdev;
}

=pod

=begin classdoc

desc

@param initrd_dir initrd working directory
@param src_device device to duplicate to dest_device
@param dest_device device receiving src_device content
@param root_size size in gigabyte to use during root resizing
@param swap_size size in gigabyte to use during swap device creation

=end classdoc

=cut

sub _initrd_deployment {
    my ($self, %args) = @_;
    General::checkParams(args     =>\%args,
                         required => [ 'initrd_dir', 'src_device', 'dest_device',
                                       'root_size', 'swap_size' ]);

    $self->generateFile(
        template_file => 'deploy.sh.tt',
        template_dir  => 'internal/initrd/sles',
        file          => $args{initrd_dir} . '/config/deploy.sh',
        data          => { deploy_src_dev   => $args{src_device},
                           deploy_dest_dev  => $args{dest_device},
                           deploy_root_size => $args{root_size},
                           deploy_swap_size => $args{swap_size} }
    );

    # TODO change hard coded root device (depend on master image partitioning)
    return '/dev/sda1';
}

=pod

=begin classdoc

generate config variables for deployment script in the initrd

@param initrd_dir initrd working directory
@param ifaces array reference of Entity::Iface instances to configure static ip
@param hostname host hostname
@param rootdev device containing the final root filesystem

=end classdoc

=cut

sub _initrd_config {
    my ($self, %args) = @_;
    General::checkParams(args     =>\%args,
                         required => ['initrd_dir', 'ifaces', 'hostname', 'rootdev']);

    $self->generateFile(
        template_file => 'storage.sh.tt',
        template_dir  => 'internal/initrd/sles',
        file          => $args{initrd_dir} . '/config/storage.sh',
        data          => { rootdev => $args{rootdev} }
    );

    my @macaddresses = ();
    my @ips = ();
    my $hostname = $args{hostname};

    IFACE:
    for my $iface (@{$args{ifaces}}) {
        my $name = $iface->getAttr(name => 'iface_name');
        my $mac  = $iface->getAttr(name => 'iface_mac_addr');
        my $ip   =  eval { $iface->getIPAddr; };
        if ($@) {
          next IFACE;
        }
        my $netmask = $iface->getPoolip->network->network_netmask;
        my $gateway = $iface->getPoolip->network->network_gateway;
        push @macaddresses, "$name:$mac";
        push @ips, $ip.'::'.$gateway.':'.$netmask.':'.$hostname.':'.$name.':none';
    }

    my $static_macaddress = join(' ', @macaddresses);
    my $static_ips = join(' ', @ips);

    $self->generateFile(
        template_file => 'network.sh.tt',
        template_dir  => 'internal/initrd/sles',
        file          => $args{initrd_dir} . '/config/network.sh',
        data          => { static_macaddress => $static_macaddress,
                           static_ips =>  $static_ips }
    );

    $self->generateFile(
        template_file => 'mount.sh.tt',
        template_dir  => 'internal/initrd/sles',
        file          => $args{initrd_dir} . '/config/mount.sh',
        data          => { rootdev => $args{rootdev},
                           rootfsck => '/sbin/fsck.ext3' }
    );
}


=pod

=begin classdoc

create the cpio file and compress it

@param initrd_dir initrd directory path
@param compress_type comression algo to use (must be 'gzip' or 'bzip2')
@param new_initrd_file full path of the new initrd to create (directory must exists)

=end classdoc

=cut

sub buildInitramfs {
    my ($self, %args) = @_;
    General::checkParams(args     =>\%args,
                         required => ['initrd_dir','compress_type', 'new_initrd_file']);

    my $econtext = $self->_host->getEContext;
    my $initrddir = $args{initrd_dir};
    my $newinitrd = $args{new_initrd_file};
    my $compress = $args{compress_type};

    # rebuild and compress the new initrd
    my $cmd = "(cd $initrddir && find . | cpio -H newc -o | $compress > $newinitrd)";
    $econtext->execute(command => $cmd);

    # finaly we remove the temporary directory
    $cmd = "rm -r $initrddir";
    $econtext->execute(command => $cmd);
}

sub service {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'services', 'mount_point' ]);

    my @services = @{$args{services}};
    $log->info("Skipping configuration of @services");
}

sub _writeNetConf {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'cluster' ]);

    $log->info("Skipping configuration of network for cluster " . $args{cluster}->cluster_name);
}

1;
