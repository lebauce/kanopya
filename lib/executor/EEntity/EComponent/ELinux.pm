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
use String::Random;
use Kanopya::Config;
use Log::Log4perl 'get_logger';
use Data::Dumper;
use Message;
use EEntity;

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

    my $hosts = $args{cluster}->getHosts();
    my @ehosts = map { EEntity->new(entity => $_) } values %$hosts;
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

    my $hosts = $args{cluster}->getHosts();
    my @ehosts = map { EEntity->new(entity => $_) } values %$hosts;
    for my $ehost (@ehosts) {
        $self->generateConfiguration(
            cluster => $args{cluster},
            host    => $ehost
        );
    }    
}

=head2 getAvailableMemory

    Return the available memory amount.

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

=head2 getTotalCpu

    Return the total cpu count.

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
                         
    push @$generated_files, $self->_generateHostname(%args);
    push @$generated_files, $self->_generateFstab(%args);
    push @$generated_files, $self->_generateResolvconf(%args);
    push @$generated_files, $self->_generateUdevPersistentNetRules(%args);
    push @$generated_files, $self->_generateHosts(
                                kanopya_domainname => $self->{_executor}->cluster_domainname,
                                %args
                            );

    return $generated_files;
}

# provision/tweak Systemimage with config files 

sub preconfigureSystemimage {
    my ($self, %args) = @_;
    General::checkParams(args     => \%args,
                         required => [ 'files', 'cluster', 'host', 'mount_point' ]);

    my $econtext = $self->getExecutorEContext;
    
    # send generated files to the image mount directory                    
    for my $file (@{$args{files}}) {
        $econtext->send(
            src  => $file->{src},
            dest => $args{mount_point}.$file->{dest}
        );
    }

    $self->_generateUserAccount(econtext => $econtext, %args);
    $self->_generateNtpdateConf(econtext => $econtext, %args);
    $self->_generateNetConf(econtext => $econtext, %args);

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
@param cluster Entity::ServiceProvider::Inside::Cluster instance
@return hashref with src as full path of the generated file, dest as the full path destination

=end classdoc

=cut

sub _generateHostname {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'cluster' ],
                                         optional => { 'path' => '/etc/hostname' });

    my $hostname = $args{host}->getAttr(name => 'host_hostname');
    my $file = $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/hostname',
        template_dir  => '/templates/components/linux',
        template_file => 'hostname.tt',
        data          => { hostname => $hostname }
    );
    
    return { src  => $file, dest => $args{path} };
}

sub _generateFstab {
    my ($self, %args) = @_;
    General::checkParams(args     => \%args,
                         required => ['cluster','host']);
    
    my $data = $self->_getEntity()->getConf();

    foreach my $row (@{$data->{linuxes_mount}}) {
        delete $row->{linux_id};
    }

    my $file = $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/fstab',
        template_dir  => '/templates/components/linux',
        template_file => 'fstab.tt',
        data          => $data 
    );
    
    return { src  => $file, dest => '/etc/fstab' };
                     
}

sub _generateHosts {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'cluster', 'host', 'kanopya_domainname' ]);

    $log->debug('Generate /etc/hosts file');

    my $nodes = $args{cluster}->getHosts();
    my @hosts_entries = ();

    # we add each nodes 
    foreach my $node (values %$nodes) {
        push @hosts_entries, {
            hostname   => $node->getAttr(name => 'host_hostname'),
            domainname => $args{kanopya_domainname},
            ip         => $node->adminIp 
        };
    }

    # we ask components for additional hosts entries
    my @components = $args{cluster}->getComponents(category => 'all');
    foreach my $component (@components) {
        my $entries = $component->getHostsEntries();
        if (defined $entries) {
            foreach my $entry (@$entries) {
                push @hosts_entries, $entry;
            }
        }
    }

    my $file = $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/hosts',
        template_dir  => '/templates/components/linux',
        template_file => 'hosts.tt',
        data          => { hosts => \@hosts_entries }
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
        template_dir  => '/templates/components/linux',
        template_file => 'resolv.conf.tt',
        data          => $data
    );
    
    return { src  => $file, dest => '/etc/resolv.conf' };
}

sub _generateUdevPersistentNetRules {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host','cluster' ]);

    my @interfaces = ();
    
    for my $iface ($args{host}->_getEntity()->getIfaces()) {
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
        template_dir  => '/templates/components/linux',
        template_file => 'udev_70-persistent-net.rules.tt',
        data          => { interfaces => \@interfaces }
    );

    return { src  => $file, dest => '/etc/udev/rules.d/70-persistent-net.rules' };
}

sub _generateUserAccount {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'cluster', 'host', 'mount_point', 'econtext' ]);

    my $econtext = $args{econtext};
    my $user = $args{cluster}->user;
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
        my $cmd = "chroot " . $args{mount_point} . " useradd -m -p '$password' $login";
        my $result = $econtext->execute(command => $cmd);

        # add a sudoers file
        $cmd = "umask 227 && echo '$login ALL=(ALL) ALL' > " . $args{mount_point} . "/etc/sudoers.d/$login";
        $result = $econtext->execute(command => $cmd);

        # add ssh pub key
        my $sshkey = $user->getAttr(name => 'user_sshkey');
        if(defined $sshkey) {
            # create ssh directory and authorized_keys file
            my $dir = $args{mount_point} . "/home/$login/.ssh";

            $cmd = "mkdir $dir";
            $result = $econtext->execute(command => $cmd);

            $cmd = "umask 177 && echo '$sshkey' > $dir/authorized_keys";
            $result = $econtext->execute(command => $cmd);

            $cmd = "chroot $args{mount_point} chown -R $login.$login /home/$login/.ssh ";
            $result = $econtext->execute(command => $cmd);
        }
    }
}

sub _generateNtpdateConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'cluster', 'host', 'mount_point', 'econtext' ]);

    my $econtext = $args{econtext};
    my $file = $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/default/ntpdate',
        template_dir  => '/templates/components/linux',
        template_file => 'ntpdate.tt',
        data          => { ntpservers => $self->{_executor}->getMasterNodeIp() }
    );

    $econtext->send(
        src  => $file,
        dest => "$args{mount_point}/etc/default/ntpdate"
    );

    # send ntpdate init script
    $file = $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/init.d/ntpdate',
        template_dir  => '/templates/components/linux',
        template_file => 'ntpdate',
        data          => { }
    );

    $econtext->send(
        src  => $file,
        dest => "$args{mount_point}/etc/init.d/ntpdate"
    );

    $econtext->execute(command => "chmod +x $args{mount_point}/etc/init.d/ntpdate");

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

        if ($iface->hasIp) {
            my $network = $iface->getPoolip->network;
            $netmask    = $network->network_netmask;
            $ip         = $iface->getIPAddr;

            if ($is_loadbalanced and not $is_masternode) {
                $gateway = $args{cluster}->getMasterNodeIp;
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
            iface_pxe => $iface->iface_pxe,
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
    
    my $econtext = $self->getExecutorEContext;
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
@param cluster Entity::ServiceProvider::Inside::Cluster instance

=end classdoc

=cut

sub customizeInitramfs {
    my ($self, %args) = @_;
    General::checkParams(args     =>\%args,
                         required => [ 'initrd_dir','cluster', 'host' ]);
    
    my $econtext = $self->getExecutorEContext;
    my $initrddir = $args{initrd_dir};

    $log->info("customize initramfs $initrddir");

    my $clustername = $args{cluster}->cluster_name;
    my $hostname = $args{host}->host_hostname;

    my $nodedir = Kanopya::Config::get('executor')->{clusters}->{directory} . "/$clustername/$hostname";

    # append files to the archive directory
    my $sourcefile = $nodedir . '/etc/udev/rules.d/70-persistent-net.rules';
    my $cmd = "(cd $initrddir && mkdir -p etc/udev/rules.d && cp $sourcefile etc/udev/rules.d)";
    $econtext->execute(command => $cmd);
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
    
    my $econtext = $self->getExecutorEContext;
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
