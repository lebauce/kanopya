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

use General;
use Entity::ServiceTemplate;

use Template;
use NetAddr::IP;
use File::Path qw(make_path);
use File::Copy;
use File::Basename;

use TryCatch;



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
        'kanopya-collector',
        'kanopya-aggregator',
        'kanopya-rulesengine',
        'kanopya-front',
        'kanopya-openstack-sync',
        'kanopya-mail-notifier',
        'kanopya-anomaly-detector',
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

        { keyname  => 'private_dir',
          caption  => 'Private data directory',
          default  => '/var/lib/kanopya/private',
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
    make_path($self->{parameters_values}->{tftp_dir});

    print "\t$self->{parameters_values}->{private_dir}\n";
    make_path($self->{parameters_values}->{private_dir});
    
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
        { path     => $self->{installpath} . '/conf/openstack-sync.conf',
          template => 'openstack-sync.conf.tt',
          data     => { admin_password => $self->{parameters_values}->{mysql_kanopya_passwd}, }
        },
        { path     => $self->{installpath} . '/conf/mail-notifier.conf',
          template => 'mail-notifier.conf.tt',
          data     => { admin_password => $self->{parameters_values}->{mysql_kanopya_passwd}, }
        },
        { path     => $self->{installpath} . '/conf/anomaly-detector.conf',
          template => 'anomaly-detector.conf.tt',
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
        { path     => $self->{installpath} . '/conf/openstack-sync-log.conf',
          template => 'openstack-sync-log.conf.tt',
          data     => { logdir => $self->{parameters_values}->{log_dir}.'/' }
        },
        { path     => $self->{installpath} . '/conf/mail-notifier-log.conf',
          template => 'mail-notifier-log.conf.tt',
          data     => { logdir => $self->{parameters_values}->{log_dir}.'/' }
        },
        { path     => $self->{installpath} . '/conf/anomaly-detector-log.conf',
          template => 'anomaly-detector-log.conf.tt',
          data     => { logdir => $self->{parameters_values}->{log_dir}.'/' }
        },
        { path     => $self->{installpath} . '/conf/webui-log.conf',
          template => 'webui-log.conf.tt',
          data     => { logdir => $self->{parameters_values}->{log_dir}.'/' }
        },
    ];

    for my $file (@$configfiles) {
        $self->_useTemplate(
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

    my $private_dir = $self->{parameters_values}->{private_dir};
    if ( (! -e $private_dir . '/kanopya_rsa') &&
         (! -e $private_dir . '/kanopya_rsa.pub') ) {
        print "\n - Dedicated root SSH keys generation...";
        system("ssh-keygen -q -t rsa -N '' -f $private_dir/kanopya_rsa; " .
               "chown puppet:puppet $private_dir/kanopya_rsa*; " .
               "install -D -m 600 $private_dir/kanopya_rsa.pub /root/.ssh/authorized_keys");
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

Load generic policies and services

=end classdoc
=cut

sub _create_generic_policies {
    my ($self) = @_;

    $self->loadPoliciesAndServices(main_file => $self->{installpath} . "/scripts/install/services/generic.json");

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
        print "failed ! Your system seems to do not support ietd daemon, $err\n";
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
        kanopya_puppet_modules => $self->{installpath} . '/templates/components/puppetmaster/modules',
        admin_domainname       => $self->{parameters_values}->{domainname},
        clusters_directory     => $path,
        kanopya_hostname       => $self->{parameters_values}->{hostname},
        dbserver               => 'localhost',
        dbpassword             => $self->{parameters_values}->{mysql_kanopya_passwd},
        puppetagent2_bootstart => 'yes',
        puppetagent2_options   => '--no-client'
    };

    $self->_useTemplate(
        template => 'components/puppetmaster/puppet.conf.tt',
        datas    => $data,
        conf     => '/etc/puppet/puppet.conf',
    );

    $self->_useTemplate(
        template => 'components/puppetmaster/fileserver.conf.tt',
        datas    => $data,
        conf     => '/etc/puppet/fileserver.conf',
    );

    $self->_useTemplate(
        template => 'components/puppetmaster/auth.conf.tt',
        datas    => $data,
        conf     => '/etc/puppet/auth.conf',
    );

    $self->_useTemplate(
        template => 'components/puppetmaster/hiera.yaml.tt',
        datas    => $data,
        conf     => '/etc/puppet/hiera.yaml',
    );

    $self->_useTemplate(
        template => 'components/puppetagent/default_puppet.tt',
        conf     => '/etc/default/puppet',
        datas    => $data,
    );

    try {
        system('mkdir -p /etc/puppet/manifests/');
        system('mkdir -p /etc/puppet/modules/');
        system('mkdir -p /var/lib/puppet/ssl/certs/');
        _writeFile(
           '/etc/puppet/manifests/site.pp',
           "Exec {\n" .
           "  path    => '/usr/bin:/usr/sbin:/bin:/sbin'\n" .
           "}\n" .
           "stage { 'system': before => Stage['main'], }\n" .
           "stage { 'finished': }\n" .
           "\$components = hiera_hash('components')\n" .
           "\$sourcepath = hiera('sourcepath')\n" .
           "hiera_include('classes')\n"
        );

        print "ok\n";
    }
    # let thorw the exception as puppet is required for a proper setup
    # catch (Kanopya::Exception::IO $err) {
    #     print "failed ! Please check your puppet configuration, $err\n";
    #     return;
    # }
    catch ($err) {
        $err->rethrow();
    }

    require Kanopya::Config;
    require EEntity;
    require Entity::ServiceProvider::Cluster;

    my $kanopya = Entity::ServiceProvider::Cluster->getKanopyaCluster();
    my @hosts = $kanopya->getHosts();
    my $kanopya_master = EEntity->new(entity => $hosts[0]);

    my $linux = $kanopya->getComponent(category => "System");
    my $elinux = EEntity->new(entity => $linux);

    $elinux->generateConfiguration(
        host    => $kanopya_master,
        cluster => $kanopya,
    );

    my $puppetmaster = $kanopya->getComponent(name => "Puppetmaster");
    my $epuppetmaster = EEntity->new(entity => $puppetmaster);

    try {
        $epuppetmaster->createHostCertificate(
            mount_point => "/tmp",
            host_fqdn   => $kanopya_master->node->fqdn
        );
    }
    # let thorw the exception as puppet is required for a proper setup
    # catch (Kanopya::Exception::IO $err) {
    #     print "failed ! Please check your puppet configuration, $err\n";
    #     return;
    # }
    catch ($err) {
        $err->rethrow();
    }

    my $puppetagent_action = 'start';
    my $puppetmaster_action = 'start';
    if(-e '/var/run/puppet/agent.pid') {
        $puppetagent_action = 'restart';
    }
    if(-e '/var/run/puppet/master.pid') {
        $puppetmaster_action = 'restart';
    }

    system('service', 'kanopya-front', 'restart');
    system('service', 'puppetmaster', $puppetmaster_action);
    system('service', 'apache2', 'restart') && system('service', 'httpd', 'restart');
    system('service', 'puppet', $puppetagent_action);

    system('mkdir -m 750 -p /var/lib/puppet/concat && chown puppet:puppet /var/lib/puppet/concat');
    EEntity->new(entity => $kanopya)->reconfigure();

    system("puppetdb ssl-setup -f");
    system('service', 'mysql', 'stop');
    system('service', 'mysql', 'start');
}


=pod
=begin classdoc

Retrieve tftp files from download.kanopya.org

=end classdoc
=cut

sub _retrieve_tftp_content {
    my ($self) = @_;

    print "\n - Retrieving TFTP directory contents from http://download.kanopya.org...\n";

    my $rsync_sshkey = '/root/.ssh/rsync_rsa';
    # Check if rsync sshkey exist on right place :
    if ( ! -e $rsync_sshkey) {
        # Get the rsync_rsa key :
        system('mkdir -p /root/.ssh; ' .
               'wget -O /root/.ssh/rsync_rsa http://download.kanopya.org/pub/rsync_rsa; ' .
               'chmod 400 /root/.ssh/rsync_rsa');
    }
    # Do a Rsync from download.kanopya.org of tftp directory content :
    system('rsync -var -e "ssh -i /root/.ssh/rsync_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" rsync@download.kanopya.org:/pub/tftp/* '.$self->{parameters_values}->{tftp_dir});
}


=pod
=begin classdoc

Restart middleware processes

=end classdoc
=cut

sub _restart_middlewares {
    my ($self) = @_;

    print "\n - Restarting required services...\n";

    for my $service ('isc-dhcp-server','iscsitarget','puppetmaster', 'xinetd',
                     'tftpd-hpa', 'snmpd', 'rabbitmq-server', 'apache2', 'httpd') {
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

=pod
=begin classdoc

Process setup with given parameters

@param $parameters hash reference return by SETUP::ask_parameters method

=end classdoc
=cut

sub process {
    my ($self) = @_;
    print "\n = Setup processing = \n";

    $self->_create_kanopya_account();
    $self->_create_directories();
    $self->_generate_kanopya_conf();
    $self->_generate_ssh_key();
    $self->_create_database();
    $self->_create_generic_policies();

    $self->_configure_dhcpd();
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
    my ($self, %args) = @_;

    my $input   = $args{template};
    my $include = $args{include} || ($self->{installpath} . '/templates');
    my $dat     = $args{datas};
    my $output  = $args{conf};
    my $config  = General::getTemplateConfiguration();

    $config->{INCLUDE_PATH} = $include;
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


=pod
=begin classod

Load services and policies initial environment.

=end classdoc
=cut

sub loadPoliciesAndServices {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "main_file" ]);

    sub _findReferencedObject {
        my $pattern = shift;

        General::checkParams(args => $pattern, required => [ "class_type" ]);

        my $referenced_class = delete $pattern->{class_type};
        print " - Found search pattern as value for referenced id of type $referenced_class\n";

        General::requireClass($referenced_class);

        my $referenced;
        try {
            $referenced = $referenced_class->find(hash => $pattern)->id;
        }
        catch ($err) {
            throw Kanopya::Exception(
                      error => "Unable to find referenced object of type $referenced_class:\n$err"
                  );
        }
        print " - Referenced object of type $referenced_class found as id: " . $referenced . "\n";

        return $referenced;
    }

    sub _validateTemplate {
        my $node = shift;

        if (ref($node) eq 'HASH') {
            for my $key (keys %$node) {
                if ($key =~ m/^.*_id$/) {
                    if (ref($node->{$key}) eq "HASH") {
                        $node->{$key} = _findReferencedObject($node->{$key});
                    }
                    else {
                        # TODO: validate the id
                    }
                }
                # BEGIN EXCEPTIONS
                elsif ($key eq "netconfs") {
                    # Specific job for netconfs, we can not handle
                    # its as the key does not contain "_id", and it is an array...
                    my @referenced;
                    for my $netconf (@{ $node->{$key} }) {
                        push @referenced, defined ref($netconf)
                                              ? _findReferencedObject($netconf)
                                              : $netconf;
                    }
                    $node->{$key} = \@referenced;
                }
                elsif ($key eq "component_type") {
                    # Argg, why component_type key has not initially be named component_type_id ?
                    if (ref($node->{$key}) eq "HASH") {
                        $node->{$key} = _findReferencedObject($node->{$key});
                    }
                    else {
                        # TODO: validate the id
                    }
                }
                # END EXCEPTIONS
                elsif (ref($node->{$key})) {
                    _validateTemplate($node->{$key});
                }
            }
        }
        elsif (ref($node) eq 'ARRAY') {
            for my $item (@{ $node }) {
                _validateTemplate($item);
            }
        }
    }

    my $dir = dirname($args{main_file});
    my @files = (basename($args{main_file}));

    my $templates = {};
    while (scalar(@files)) {
        # Handle the first file of the list
        my $json_file = $dir . '/' . $files[0];

        print "Load service file '$json_file'...\n\n";

        if (! defined $templates->{$json_file}) {
            # Open and parse services definition json file.
            my $json = do {
                open(my $json_fh, "<:encoding(UTF-8)", $json_file)
                    or die("Can't open $json_file: $!\n");
                local $/;
                <$json_fh>
            };

            try {
                $templates->{$json_file} = JSON->new->decode($json);
            }
            catch ($err) {
                throw Kanopya::Exception::IO(
                          error => "Malformed json file:\n$err"
                      );
            }
        }

        if (defined $templates->{$json_file}->{require}) {
            if (ref($templates->{$json_file}->{require}) ne 'ARRAY') {
                throw Kanopya::Exception(
                          error => "Malformed json file: 'required' key must have an array as value"
                      );
            }
            for my $required (@{ $templates->{$json_file}->{require} }) {
                print " - Found required json service file '$required.json'\n";
                unshift @files, $required . ".json";
            }
            delete $templates->{$json_file}->{require};
            next;
        }

        try {
            # Firstly create policies
            if (defined $templates->{$json_file}->{policies}) {
                print "Create policies...\n\n";
                for my $policy (values %{$templates->{$json_file}->{policies}}) {
                    General::checkParams(args => $policy, required => [ "policy_name", "policy_type" ]);

                    print "Policy: $policy->{policy_name}...\n";

                    # Build the type
                    my $policy_type = "Entity::Policy::" . ucfirst($policy->{policy_type}) . "Policy";
                    General::requireClass($policy_type);

                    # Validate the policy template
                    _validateTemplate($policy);

                    # Create
                    my $instance = $policy_type->findOrCreate(%$policy);

                    print " - ok, policy created with id " . $instance->id . "\n";
                }
            }

            # Then create services
            if (defined $templates->{$json_file}->{services}) {
                print "\nCreate services...\n\n";
                for my $service (values %{$templates->{$json_file}->{services}}) {
                    General::checkParams(args => $service, required => [ "service_name" ]);

                    print "Service: $service->{service_name}...\n";

                    # Validate the service template
                    _validateTemplate($service);

                    # Create
                    my $instance = Entity::ServiceTemplate->findOrCreate(%$service);

                    print " - ok, service created with id " . $instance->id . "\n";
                }
            }
        }
        catch ($err) {
            print "\n";

            throw Kanopya::Exception(
                      error => "Load services from $json_file failed:\n$err"
                  );
        }

        # remove the handled file from the file list
        shift @files;
    }
}

1;
