# Copyright © 2012 Hedera Technology SAS
#
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

Setup class implementing linux setup questions and actions

@since    2012-Nov-1
@instance hash
@self     $self

=end classdoc
=cut

package Setup::Linux;
use parent 'Setup';

use strict;
use warnings;
use Template;
use NetAddr::IP;
use File::Path qw(make_path);
use File::Copy;

use TryCatch;
my $err;


=pod
=begin classdoc

Load structure from file to set parameters for setup processing

@param $file file to read

=end classdoc
=cut

sub _load_file {
    my ($self, $file) = @_;
    open(my $FILE, '<', $file) or die "Unable to open $file $!";
    my @lines = <$FILE>;
    close($FILE);
    my $parameters_values = {};
    LINE:
    for my $line (@lines) {
        if($line =~ /^#/ || $line eq '\n') {
            next LINE;
        } else {
            my ($key, $value) = split(/\s/, $line);
            $parameters_values->{$key} = $value;
        }
    }

    return $parameters_values;
}


=pod
=begin classdoc

Initialize structure used to ask/set parameters for setup processing

=end classdoc
=cut

sub _init {
    my ($self) = @_;
    $self->{licence_path} = $self->{installpath} . '/UserLicence';
    $self->{template_path} = $self->{installpath} . '/scripts/install/templates';
    $self->{dbschema_path} = $self->{installpath} . '/scripts/database/mysql';
    $self->{kanopya_services} = [
        'kanopya-executor',
        'kanopya-state-manager',
        'kanopya-collector',
        'kanopya-aggregator',
        'kanopya-rulesengine',
        'kanopya-front',
    ];

    $self->{parameters} = [
        { title => 'Directories setting' },

        { keyname  => 'clusters_dir',
          caption  => 'Configuration nodes files directory',
          default  => '/var/lib/kanopya/clusters',
          validate => '_validate_dir' },

        { keyname  => 'masterimages_dir',
          caption  => 'Master images directory',
          default  => '/var/lib/kanopya/masterimages',
          validate => '_validate_dir' },

        { keyname  => 'tftp_dir',
          caption  => 'Tftp boot files directory',
          default  => '/var/lib/kanopya/tftp',
          validate => '_validate_dir', },  

        { keyname  => 'log_dir',
          caption  => 'Log files directory',
          default  => '/var/log/kanopya',
          validate => '_validate_dir', },

        { keyname  => 'sessions_dir',
          caption  => 'Sessions files directory',
          default  => '/tmp/kanopya-sessions',
          validate => '_validate_dir', },    

        { title => 'Database setting' },

        { keyname => 'mysql_host',
          caption => 'Mysql server ip address',
          default => '127.0.0.1',
          validate => '_validate_ip', },

        { keyname => 'mysql_port',
          caption => 'Mysql port',
          default => 3306,
          validate => '_validate_port', },

        { keyname   => 'mysql_root_passwd',
          caption   => 'Mysql root password',
          hideinput => 1,
          validate => '_validate_mysql_connection', },

        { keyname => 'mysql_kanopya_passwd',
          caption => 'Mysql kanopya user password',
          default => 'K4n0pY4', },

        { title => 'Network setting' },

        { keyname  => 'domainname',
          caption  => 'Domain name for kanopya administration',
          default  => 'kanopya.localdomain',
          validate => '_validate_domainname', }, 

        { keyname  => 'admin_iface',
          choices  => \&_get_ifaces,
          caption  => 'Network interface for kanopya administration',
          default  => sub { return ($self->_get_ifaces())[0] }, 
          validate => '_validate_iface' }, 

        { keyname  => 'admin_net_ip',
          caption  => 'Network ip address for kanopya administration network',
          default  => '10.0.0.0',
          validate => '_validate_ip' }, 

        { keyname => 'admin_net_mask',
          caption => 'Ip mask for kanopya administration network',
          default => '255.255.255.0', },

        { keyname => 'admin_ip',
          caption => 'First ip address to use in the administration network (kanopya host must be configured with this ip)',
          default => sub { return $self->_get_first_ip } },

        { keyname => 'admin_net_size',
          caption => 'Ip addresses count to use in this pool',
          default => '250', },

        { keyname => 'admin_net_gateway',
          caption => 'Ip address gateway for kanopya administration network',
          default => '0.0.0.0', },

        { title => 'NAS setting' },

        { keyname  => 'vg_name',
          caption  => 'LVM volume group dedicated to kanopya',
          default  => sub { return ($self->_get_vgs())[0] }, 
          validate => '_validate_vg', },
    ];
}


=pod
=begin classdoc

Test directory validity

@param $value directory to test

=end classdoc
=cut

sub _validate_dir {
    my ($self, $value) = @_;
    if (-e $value) {
        return { msg => "WARNING: $value already exists" };
    }
    return { value => $value };
}


=pod
=begin classdoc

Retrieve network interfaces

@return @ifaces list of detected network interfaces

=end classdoc
=cut

sub _get_ifaces {
    my @ifaces_list = `ip -o link | awk '{ print \$2 }'`;
    my @ifaces = grep { $_ ne 'lo' } (map { substr($_, 0, -2) } @ifaces_list);
    return @ifaces;
}


=pod
=begin classdoc

Test network interface validity

@param @value network interface name

=end classdoc
=cut

sub _validate_iface {
    my ($self, $value) = @_;
    my @ifaces = _get_ifaces();
    for(@ifaces) {
        if($value eq $_) {
            return { value => $value };
        }
    }
    return { error => 1, msg => "Invalid interface $value" };
}


=pod
=begin classdoc

Generate first ip address from admin network parameters

=end classdoc
=cut

sub _get_first_ip {
    my ($self) = @_;
    my $net = $self->{parameters_values}->{admin_net_ip};
    my $mask = $self->{parameters_values}->{admin_net_mask};
    my $ip = new NetAddr::IP($net,$mask);
    return $ip->first()->addr();
}


=pod
=begin classdoc

Retrieve volume groups

@return @vgs list of detected volume groups

=end classdoc
=cut

sub _get_vgs {

    my @vgs_list = `vgs  --noheadings -o vg_name`;
    chomp(@vgs_list);

    my @vgs = map { my $vg = $_; $vg =~ s/\s//g; return $vg } @vgs_list;

    return @vgs;
}


=pod
=begin classdoc

Test volume group validity

@param @value volume group name

=end classdoc
=cut

sub _validate_vg {
    my ($self, $value) = @_;
    my @vgs = _get_vgs();
    for(@vgs) {
        if($value eq $_) {
            return { value => $value };
        }
    }
    return { error => 1, msg => "Invalid volume group $value" };
}


=pod
=begin classdoc

Retrieve/generate additionnal data parameters

=end classdoc
=cut

sub complete_parameters {
    my ($self) = @_;
    
    # generate random salt for password hashes
    $self->{parameters_values}->{crypt_salt} = join '', ('.','/',0..9,'A'..'Z','a'..'z')[rand 64, rand 64];
    
    # retrieve chosen interface mac address and ip
    my $iface = $self->{parameters_values}->{admin_iface};
    my ($mac, $ip);
    my $output = `ip -o addr show dev $iface`;
    if($output =~ /ether\s(.{2}:.{2}:.{2}:.{2}:.{2}:.{2})\s/) {
        $mac = $1;
    }
    if($output =~ /inet\s(.{1,3}\..{1,3}\..{1,3}\..{1,3})\//) {
        $ip = $1;
    }
    
    $self->{parameters_values}->{admin_iface_mac} = $mac;
    $self->{parameters_values}->{admin_actual_ip} = $ip;

    # retrieve volume group size and free space
    my $vg_name = $self->{parameters_values}->{vg_name};
    my $vg_sizes = `vgs --noheadings $vg_name --units B -o vg_size,vg_free --nosuffix --separator '|'`;
    chomp($vg_sizes);
    $vg_sizes =~ s/^\s+//;
    my ($vg_size, $vg_free_space ) = split(/\|/,$vg_sizes);
    $self->{parameters_values}->{vg_size} = $vg_size;
    $self->{parameters_values}->{vg_free_space} = $vg_free_space;
    
    # retrieve physical volumes of volume group
    my @pvs = `pvs --noheadings --separator '|' -o pv_name,vg_name  | grep $vg_name | cut -d'|' -f1`;
    chomp(@pvs);
    foreach my $pv (@pvs) {
        $pv =~ s/^\s+//;
    }

    $self->{parameters_values}->{pvs} = \@pvs;

    # get hostname
    $self->{parameters_values}->{hostname} = `hostname`;
    chomp($self->{parameters_values}->{hostname});

    # generate iscsi initiatorname
    $self->{parameters_values}->{initiatorname} = 'iqn.kanopya';
}

=pod
=begin classdoc

Serialize final parameters on disk.

=end classdoc
=cut

sub serialize_parameters {
    my $self  = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ 'output_file' ], optional => { 'test' => 0 });

    my $serialized = '';
    if (! $args{test}) {
        for my $key (keys %{ $self->{parameters_values} }) {
            if (! ref($self->{parameters_values}->{$key})) {
                $serialized .= "$key $self->{parameters_values}->{$key}\n";
            }
        }
    }

    _writeFile($args{output_file}, $serialized);
}


=pod
=begin classdoc

Create kanopya linux user

=end classdoc
=cut

sub _create_kanopya_account {
    my ($self) = @_;
    my $output = `grep kanopya /etc/passwd 2>/dev/null`;

    if (not $output) {
        print "\n - kanopya account creation...";
        system("useradd kanopya -r -c 'Kanopya User' -s '/bin/false' -b '/opt'");
        print "ok\n";
    } else {
        print "\n - kanopya account already exists, skipping creation.\n";
    }
}


=pod
=begin classdoc

create directories 

=end classdoc
=cut

sub _create_directories {
    my ($self) = @_;
    print "\n - Directories creation...\n";
    
    print "\t$self->{parameters_values}->{log_dir}\n";
    make_path($self->{parameters_values}->{log_dir} . "/workflows");
    
    print "\t$self->{parameters_values}->{clusters_dir}\n";
    make_path($self->{parameters_values}->{clusters_dir});
    
    print "\t$self->{parameters_values}->{masterimages_dir}\n";
    make_path($self->{parameters_values}->{masterimages_dir});
    
    print "\t$self->{parameters_values}->{tftp_dir}\n";
    system('mkdir -p '.$self->{parameters_values}->{tftp_dir});
    
    print "\t$self->{parameters_values}->{sessions_dir}\n";
    make_path($self->{parameters_values}->{sessions_dir});
    system('chown -R kanopya.kanopya '.$self->{parameters_values}->{sessions_dir});
}


=pod
=begin classdoc

Generate kanopya config and log files

=end classdoc
=cut

sub _generate_kanopya_conf {
    my ($self) = @_;
    print "\n - Configuration files generation...";
    my $configfiles = [
        # components list
        { path => $self->{installpath} . '/conf/components.conf',
          template => 'components.conf.tt',
        },
        # config files
        { path     => $self->{installpath} . '/conf/executor.conf',
          template => 'executor.conf.tt',
          data     => { logdir            => $self->{parameters_values}->{log_dir},
                        masterimages_dir  => $self->{parameters_values}->{masterimages_dir}, 
                        tftp_dir          => $self->{parameters_values}->{tftp_dir}, 
                        clusters_dir      => $self->{parameters_values}->{clusters_dir},
                        internal_net_add  => $self->{parameters_values}->{admin_ip},
                        internal_net_mask => $self->{parameters_values}->{admin_net_mask},
                        admin_password    => $self->{parameters_values}->{mysql_kanopya_passwd}, }
        },
        { path     => $self->{installpath} . '/conf/aggregator.conf',
          template => 'aggregator.conf.tt',
          data     => { admin_password => $self->{parameters_values}->{mysql_kanopya_passwd}, }
        },
        { path     => $self->{installpath} . '/conf/rulesengine.conf',
          template => 'rulesengine.conf.tt',
          data     => { admin_password => $self->{parameters_values}->{mysql_kanopya_passwd}, }
        },
        { path     => $self->{installpath} . '/conf/monitor.conf',
          template => 'monitor.conf.tt',
          data     => { internal_net_add  => $self->{parameters_values}->{admin_ip},
                        internal_net_mask => $self->{parameters_values}->{admin_net_mask},
                        admin_password    => $self->{parameters_values}->{mysql_kanopya_passwd},}
        },
        { path     => $self->{installpath} . '/conf/libkanopya.conf',
          template => 'libkanopya.conf.tt',
          data     => { internal_net_add  => $self->{parameters_values}->{admin_ip},
                        internal_net_mask => $self->{parameters_values}->{admin_net_mask},
                        db_user           => 'kanopya',
                        dbip              => $self->{parameters_values}->{mysql_host},
                        dbport            => $self->{parameters_values}->{mysql_port},
                        admin_password    => $self->{parameters_values}->{mysql_kanopya_passwd},
                        logdir            => $self->{parameters_values}->{log_dir},
                        crypt_salt        => $self->{parameters_values}->{crypt_salt}}
        },
        { path     => $self->{installpath} . '/ui/Frontend/config.yml',
          template => 'dancer_cfg.tt',
          data     => { product       => 'KIM',
                        show_gritters => 1,
                        sessions_dir  => $self->{parameters_values}->{sessions_dir},
                        log_directory => $self->{parameters_values}->{log_dir}, }
        },

        # log files
        { path     => $self->{installpath} . '/conf/executor-log.conf',
          template => 'executor-log.conf.tt',
          data     => { logdir => $self->{parameters_values}->{log_dir}.'/' }
        },
        { path     => $self->{installpath} . '/conf/state-manager-log.conf',
          template => 'state-manager-log.conf.tt',
          data     => { logdir => $self->{parameters_values}->{log_dir}.'/' }
        },
        { path     => $self->{installpath} . '/conf/aggregator-log.conf',
          template => 'aggregator-log.conf.tt',
          data     => { logdir => $self->{parameters_values}->{log_dir}.'/' }
        },
        { path     => $self->{installpath} . '/conf/collector-log.conf',
          template => 'collector-log.conf.tt',
          data     => { logdir => $self->{parameters_values}->{log_dir}.'/' }
        },
        { path     => $self->{installpath} . '/conf/monitor-log.conf',
          template => 'monitor-log.conf.tt',
          data     => { logdir => $self->{parameters_values}->{log_dir}.'/' }
        },
        { path     => $self->{installpath} . '/conf/rulesengine-log.conf',
          template => 'rulesengine-log.conf.tt',
          data     => { logdir => $self->{parameters_values}->{log_dir}.'/' }
        },
        { path     => $self->{installpath} . '/conf/webui-log.conf',
          template => 'webui-log.conf.tt',
          data     => { logdir => $self->{parameters_values}->{log_dir}.'/' }
        },
    ];

    for my $file (@$configfiles) {
        _useTemplate(
            include  => $self->{template_path},
            template => $file->{template},
            datas    => $file->{data},
            conf     => $file->{path},
        );
    }
    print "ok\n";
}


=pod
=begin classdoc

SSH key creation for root

=end classdoc
=cut

sub _generate_ssh_key {
    my ($self) = @_;
    if ( (! -e '/root/.ssh/kanopya_rsa') && (! -e '/root/.ssh/kanopya_rsa.pub') ) {
        if (! -e '/root/.ssh') {
            make_path('/root/.ssh')
        }
        print "\n - Dedicated root SSH keys generation...";
        system("ssh-keygen -q -t rsa -N '' -f /root/.ssh/kanopya_rsa");
        print "ok\n";

    } else {
        print "\n - Dedicated root SSH keys already exists, skipping generation.\n";
    }
}


=pod
=begin classdoc

Create user and database shema

=end classdoc
=cut

sub _create_database {
    my ($self) = @_;

    my $host = $self->{parameters_values}->{mysql_host};
    my $port = $self->{parameters_values}->{mysql_port};
    my $passwd = $self->{parameters_values}->{mysql_root_passwd};
    my $userpasswd = $self->{parameters_values}->{mysql_kanopya_passwd};

    $self->_createMySQLUser(user       => 'kanopya',
                            password   => $self->{parameters_values}->{mysql_kanopya_passwd},
                            privileges => "ALL PRIVILEGES",);

    # drop previous kanopya database
    print "\n - Drop old Kanopya database if present...";
    $self->_execSQL('drop database if exists kanopya');
    print "ok\n";

    # schema creation
    print "\n - Create kanopya database...";
    system("mysql -h $host  -P $port -u kanopya -p$userpasswd < $self->{dbschema_path}/schemas/Schemas.sql");
    print "ok\n";

    # components schema
    print "\n - Create components schemas...";
    open(my $FILE, '<', $self->{installpath} . '/conf/components.conf');
    my @lines = <$FILE>;
    close($FILE);
    LINE:
    for my $line (@lines) {
       chomp($line);
       if(( ! $line ) || ( $line =~ /^#/ )) {
           next LINE;
       }
       system("mysql -h $host  -P $port -u kanopya -p$userpasswd < $self->{dbschema_path}/schemas/components/$line.sql");
    }
    print "ok\n";

    # populate initial data
    my %datas = (
        kanopya_vg_name          => $self->{parameters_values}->{vg_name},
        kanopya_vg_size          => $self->{parameters_values}->{vg_size},
        kanopya_vg_free_space    => $self->{parameters_values}->{vg_free_space},
        kanopya_pvs              => $self->{parameters_values}->{pvs},
        poolip_addr              => $self->{parameters_values}->{admin_ip},
        poolip_netmask           => $self->{parameters_values}->{admin_net_mask},
        poolip_mask              => $self->{parameters_values}->{admin_net_size},
        poolip_gateway           => $self->{parameters_values}->{admin_net_gateway},
        ipv4_internal_network_ip => $self->{parameters_values}->{admin_net_ip},
        admin_domainname         => $self->{parameters_values}->{domainname},
        kanopya_hostname         => $self->{parameters_values}->{hostname},
        kanopya_initiator        => $self->{parameters_values}->{initiatorname},
        mb_hw_address            => $self->{parameters_values}->{admin_iface_mac},
        admin_interface          => $self->{parameters_values}->{admin_iface},
        admin_password           => $self->{parameters_values}->{mysql_kanopya_passwd},
        admin_kernel             => undef,
        tmstp                    => time()
    );


    my %nsinfo = $self-> _getNameServerInfo();
    if (@{ $nsinfo{nameservers} } > 0) {
        $datas{kanopya_nameserver1} = $nsinfo{nameservers}->[0];
    }

    if (@{ $nsinfo{nameservers} } > 1) {
        $datas{kanopya_nameserver2} = $nsinfo{nameservers}->[2];
    }

    require PopulateDB;
    print "\n - Populating database...\n";
    populateDB(login    => 'admin',
               password => $self->{parameters_values}->{mysql_kanopya_passwd},
               %datas);
}


=pod
=begin classdoc

Configure dhcpd

=end classdoc
=cut

sub _configure_dhcpd {
    my ($self) = @_;

    print "\n - Dhcpd reconfiguration...";

    _writeFile('/etc/dhcp/dhcpd.conf',
              "ddns-update-style none;\n" .
              "default-lease-time 600;\n" .
              "max-lease-time 7200;\n" .
              "log-facility local7;\n" .
              'subnet ' . $self->{parameters_values}->{admin_net_ip} . ' ' .
              'netmask ' . $self->{parameters_values}->{admin_net_mask} . "{}\n");
    print "ok\n";
}

=pod
=begin classdoc

Configure iscsitarget

=end classdoc
=cut

sub _configure_iscsitarget {
    my ($self) = @_;
    print "\n - Iscsitarget reconfiguration...";

    try {
        _writeFile('/etc/iet/ietd.conf', "");
        _writeFile('/etc/default/iscsitarget', "ISCSITARGET_ENABLE=true");

        print "ok\n";
    }
    catch (Kanopya::Exception::IO $err) {
        print "failed ! Your system seems to do not support ietd daemon, $err";
    }
    catch ($err) {
        $err->rethrow();
    }
}


=pod
=begin classdoc

Configure rabbitmq

=end classdoc
=cut

sub _configure_rabbitmq {
    my ($self) = @_;
    print "\n - Rabbitmq configuration...";

    my $password = $self->{parameters_values}->{mysql_kanopya_passwd};

    for my $user ("executor", "aggregator", "rulesengine", "monitor", "api") {
        if (system ("rabbitmqctl list_users | grep -P '^$user\t'")) {
            system ("rabbitmqctl add_user $user $password");
            system ("rabbitmqctl set_permissions $user '.*' '.*' '.*'");
        }
        else {
            print "Changing password for user $user\n";
            system ("rabbitmqctl change_password $user $password");
        }
    }
    print "ok\n";
}


=pod
=begin classdoc

Configure snmpd

=end classdoc
=cut

sub _configure_snmpd {
    my ($self) = @_;
    print "\n - Snmpd reconfiguration...";

    _useTemplate(
        include  => $self->{installpath} . '/templates/components/snmpd',
        data     => { internal_ip_add => $self->{parameters_values}->{admin_ip} },
        conf     => '/etc/snmp/snmpd.conf',
        template => 'snmpd.conf.tt',
    );

    _useTemplate(
        include  => $self->{installpath} . '/templates/components/snmpd',
        data     => { internal_ip_add => $self->{parameters_values}->{admin_ip} },
        conf     => '/etc/default/snmpd',
        template => 'default_snmpd.tt',
    );
    print "ok\n";
}


=pod
=begin classdoc

Configure puppetmaster

=end classdoc
=cut

sub _configure_puppetmaster {
    my ($self) = @_;
    print "\n - Puppet master reconfiguration...\n";

    $self->_execSQL("drop database if exists puppet");
    $self->_execSQL("CREATE DATABASE puppet");
    $self->_createMySQLUser(user       => "puppet",
                            password   => $self->{parameters_values}->{mysql_kanopya_passwd},
                            privileges => "ALL PRIVILEGES");

    my $path = $self->{parameters_values}->{clusters_dir};
    if($path =~ /\/$/) {
        chop($path);
    }

    my $data = {
        kanopya_puppet_modules => '/opt/kanopya/templates/components/puppetmaster/modules',
        admin_domainname       => $self->{parameters_values}->{domainname},
        clusters_directory     => $path,
        kanopya_hostname       => $self->{parameters_values}->{hostname},
        dbserver               => 'localhost',
        dbpassword             => $self->{parameters_values}->{mysql_kanopya_passwd},
        puppetagent2_bootstart => 'yes',
        puppetagent2_options   => '--no-client'
    };

    _useTemplate(
        include  => '/templates/components/puppetmaster',
        template => 'puppet.conf.tt',
        datas    => $data,
        conf     => '/etc/puppet/puppet.conf',
    );

    _useTemplate(
        include  => '/templates/components/puppetmaster',
        template => 'fileserver.conf.tt',
        datas    => $data,
        conf     => '/etc/puppet/fileserver.conf',
    );

    _useTemplate(
        include  => '/templates/components/puppetmaster',
        template => 'auth.conf.tt',
        datas    => $data,
        conf     => '/etc/puppet/auth.conf',
    );

    _useTemplate(
        include  => '/templates/components/puppetagent',
        template => 'default_puppet.tt',
        conf     => '/etc/default/puppet',
        datas    => $data,
    );

    _writeFile('/etc/puppet/manifests/site.pp',
          "Exec {\n" .
          "  path    => '/usr/bin:/usr/sbin:/bin:/sbin'\n" .
          "}\n" .
          "stage { 'system': before => Stage['main'], }\n" .
          "stage { 'finished': }\n" .
          "import \"nodes/*.pp\"\n");

    use Kanopya::Config;
    use EEntity;
    use Entity::ServiceProvider::Cluster;

    my $kanopya = Entity::ServiceProvider::Cluster->getKanopyaCluster();
    my $linux = $kanopya->getComponent(category => "System");

    my @hosts = $kanopya->getHosts();
    my $kanopya_master = $hosts[0];
    my $puppetmaster = $kanopya->getComponent(name => "Puppetmaster");
    my $fstab_puppet_definitions = $linux->getPuppetDefinition(
                                       host    => $kanopya_master,
                                       cluster => $kanopya,
                                   );

    my $epuppetmaster = EEntity->new(entity => $puppetmaster);
    my $fqdn = $kanopya_master->node->node_hostname . "." . $kanopya->cluster_domainname;

    $epuppetmaster->createHostCertificate(
        mount_point => "/tmp",
        host_fqdn   => $fqdn
    );

    $epuppetmaster->createHostManifest(
        host_fqdn          => $fqdn,
        puppet_definitions => $fstab_puppet_definitions,
        sourcepath         => $kanopya->cluster_name . '/' . $kanopya_master->node->node_hostname
    );

    my $puppetagent_action = 'start';
    my $puppetmaster_action = 'start';
    if(-e '/var/run/puppet/agent.pid') {
        $puppetagent_action = 'restart';
    }
    if(-e '/var/run/puppet/master.pid') {
        $puppetmaster_action = 'restart';
    }
    system('/etc/init.d/puppetmaster', $puppetmaster_action);
    system('/etc/init.d/puppet', $puppetagent_action);

    system('mkdir -m 750 /var/lib/puppet/concat && chown puppet:puppet /var/lib/puppet/concat');
    EEntity->new(entity => $kanopya)->reconfigure();

}


=pod
=begin classdoc

Retrieve tftp files from 192.168.0.173

=end classdoc
=cut

sub _retrieve_tftp_content {
    my ($self) = @_;

    print "\n - Retrieving TFTP directory contents from http://192.168.0.173...\n";

    my $rsync_sshkey = '/root/.ssh/rsync_rsa';
    # Check if rsync sshkey exist on right place :
    if ( ! -e $rsync_sshkey) {
        # Get the rsync_rsa key :
        system('wget http://192.168.0.173:8011/rsync_rsa');
        # Move the key and set the correct rights ;
        system('mv rsync_rsa /root/.ssh/;chmod 400 /root/.ssh/rsync_rsa');
    }
    # Do a Rsync from 192.168.0.173 of tftp directory content :
    system('rsync -var -e "ssh -p 2211 -i /root/.ssh/rsync_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" rsync@192.168.0.173:/pub/tftp/* '.$self->{parameters_values}->{tftp_dir});
}


=pod
=begin classdoc

Restart middleware processes

=end classdoc
=cut

sub _restart_middlewares {
    my ($self) = @_;

    print "\n - Restarting required services...\n";

    for my $service ('isc-dhcp-server','iscsitarget','puppetmaster', 'tftpd-hpa', 'snmpd', 'rabbitmq-server') {
        system("service $service restart");
    }
    system("service inetutils-inetd stop");
}


=pod
=begin classdoc

Start kanopya processes

=end classdoc
=cut

sub _start_kanopya_services {
    my ($self) = @_;

    print "\n - Restarting Kanopya services...\n";

    for my $service (@{$self->{kanopya_services}}) {
        system("service $service start");
    }
}

sub _getNameServerInfo {
    my ($domain, @nameservers);

    open my $FILE, '<', '/etc/resolv.conf';
    my @lines = <$FILE>;
    close($FILE);

    for my $line (@lines) {
        if($line =~ /^nameserver (.+)/) {
            push @nameservers, $1;
            next;
        }

        if($line =~ /^domain (.+)/) {
            $domain = $1;
            next;
        }
    }

    return ( domain => $domain, nameservers => \@nameservers );
}

sub _createTemplatesSymLink {

    my $templateslink = '/templates';
    if (not -e $templateslink) {
        eval {
            symlink('/opt/kanopya/templates', $templateslink);
        };
    print "Your system does not support symbolic links", "\n" if $@; 
    }
}


=pod
=begin classdoc

Process setup with given parameters

@param $parameters hash reference return by SETUP::ask_parameters method

=end classdoc
=cut

sub process {
    my ($self) = @_;
    print "\n = Setup processing = \n";

    $self->_createTemplatesSymLink();
    $self->_create_kanopya_account();
    $self->_create_directories();
    $self->_generate_kanopya_conf();
    $self->_generate_ssh_key();
    $self->_create_database();

    $self->_configure_dhcpd();
    $self->_configure_snmpd();
    $self->_configure_iscsitarget();
    $self->_configure_puppetmaster();
    $self->_configure_rabbitmq();

    # copy logrotate file
    copy($self->{installpath} . '/scripts/install/templates/logrotate-kanopya', '/etc/logrotate.d') || die "$!";

    # copy syslog-ng config
    copy($self->{installpath} . '/scripts/install/templates/syslog-ng.conf', '/etc/syslog-ng') || die "$!";

    $self->_retrieve_tftp_content();

    # warn if actual ip configuration does not match input configuration
    if ($self->{parameters_values}->{admin_actual_ip} ne $self->{parameters_values}->{admin_ip}) {
        print "\nWARNING actual ip configuration for network interface $self->{parameters_values}->{admin_iface} ($self->{parameters_values}->{admin_actual_ip})
does not match your input configuration ($self->{parameters_values}->{admin_ip}) ;
don't forget to reconfigure it\n";
    }

    $self->_restart_middlewares();
    $self->_start_kanopya_services();
}


=pod
=begin classod

Init and process Template

=end classdoc
=cut

sub _useTemplate {
    my %args = @_;

    my $input   = $args{template};
    my $include = $args{include};
    my $dat     = $args{datas};
    my $output  = $args{conf};

    my $config = {
            INCLUDE_PATH => $include,
            INTERPOLATE  => 1,
            POST_CHOMP   => 1,
            EVAL_PERL    => 1,
    };
    my $template = Template->new($config);

    $template->process($input, $dat, $output) || do {
            print "error while generating $output: $!";
    };
}


=pod
=begin classod

 Write into a file in '>' mode

=end classdoc
=cut

sub _writeFile {
    my ($path_file, $line) = @_;

    open (my $FILE, ">", $path_file)
        or throw Kanopya::Exception::IO(error => "an error occured while opening $path_file: $!");
    print $FILE $line;
    close($FILE);
}


=pod
=begin classod

Execute a given SQL query

=end classdoc
=cut

sub _execSQL {
    my ($self,$sql) = @_;

    my $host = $self->{parameters_values}->{mysql_host};
    my $port = $self->{parameters_values}->{mysql_port};
    my $pwd  = $self->{parameters_values}->{mysql_root_passwd};

    return system("mysql -h $host -P $port -u root -p$pwd -e \"$sql\"");
}


=pod
=begin classod

Create a mysql user and grand him rights

=end classdoc
=cut

sub _createMySQLUser {
    my ($self,%args) = @_;

    $args{database} = $args{database} || $args{user};

    my $query = "mysql -h $self->{parameters_values}->{mysql_host} " .
                "-P $self->{parameters_values}->{mysql_port} " .
                "-u root -p$self->{parameters_values}->{mysql_root_passwd} " .
                "-e \"use mysql; " .
                "SELECT user FROM mysql.user WHERE user='$args{user}';\" " .
                " | grep $args{user};";
    my $user = `$query`;

    if (!$user) {
        print "\n - Creating user $args{user}...";

        $self->_execSQL("CREATE USER '" . $args{user} . "'\@'localhost' " .
                "IDENTIFIED BY '$args{password}'") == 0
            or die "error while creating mysql user: $!" == 0
            or die "error while creating mysql user: $!";
        eval {
            $self->_execSQL("CREATE USER '$args{user}' IDENTIFIED BY '$args{password}'");
        };
        print "ok\n";
    }
    else {
        print "\n - User $args{user} already exists, skipping creation.\n";
    }

    #We grant all privileges to kanopya database for $db_user
    print "\n - Granting all privileges on $args{database} database to $args{user}...";
    $self->_execSQL("GRANT " . $args{privileges} . " ON $args{database}.* TO '$args{user}' WITH GRANT OPTION") == 0
         or die "error while granting privileges to $args{user}: $!";
}

1;
