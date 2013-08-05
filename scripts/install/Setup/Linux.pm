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
    $self->{licence_path} = $self->{installpath}.'/UserLicence';
    $self->{template_path} = $self->{installpath}.'/scripts/install/templates';
    $self->{dbschema_path} = $self->{installpath}.'/scripts/database/mysql';
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
    if(-e $value) {
        return { error => 1, msg => "$value already exists" };
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
    $self->{parameters_values}->{pvs} = \@pvs;
    
    # get hostname
    $self->{parameters_values}->{hostname} = `hostname`;
    
    # generate iscsi initiatorname
    $self->{parameters_values}->{initiatorname} = 'iqn.toto';
    
    
}

=pod

=begin classdoc

Create kanopya linux user

=end classdoc

=cut

sub _create_kanopya_account {
    my ($self) = @_;
    my $output = `grep kanopya /etc/passwd`;
    
    if(not $output) {
        print "\n - kanopya account creation\n";
        system("useradd kanopya -r -c 'Kanopya User' -s '/bin/false' -b '/opt'");
    } else {
        print "\n - kanopya account already exists, skipping creation\n";
    }
}

=pod

=begin classdoc

create directories 

=end classdoc

=cut

sub _create_directories {
    my ($self) = @_;
    print "\n - Directories creation\n";
    
    print "$self->{parameters_values}->{log_dir}\n";
    make_path($self->{parameters_values}->{log_dir});
    
    print "$self->{parameters_values}->{clusters_dir}\n";
    make_path($self->{parameters_values}->{clusters_dir});
    
    print "$self->{parameters_values}->{masterimages_dir}\n";
    make_path($self->{parameters_values}->{masterimages_dir});
    
    print "$self->{parameters_values}->{tftp_dir}\n";
    system('mkdir -p '.$self->{parameters_values}->{tftp_dir});
    
    print "$self->{parameters_values}->{sessions_dir}\n";
    make_path($self->{parameters_values}->{sessions_dir});
    system('chown -R kanopya.kanopya '.$self->{parameters_values}->{sessions_dir});
    
    # ? est bien utile ?
    #system('chown -R kanopya.kanopya '.$self->{installpath});
    
}

=pod

=begin classdoc

Generate kanopya config and log files

=end classdoc

=cut

sub _generate_kanopya_conf {
    my ($self) = @_;
    print "\n - Configuration files generation\n";
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
    
    my $template_config = {
        INCLUDE_PATH => $self->{template_path},
        INTERPOLATE  => 1,
        POST_CHOMP   => 1,
        EVAL_PERL    => 1,
    };
    
    my $template = Template->new($template_config);
    for my $file (@$configfiles) {
        print "$file->{path}\n";
        $template->process($file->{template}, 
                           $file->{data}, 
                           $file->{path}) || 
            die $template->error(), "\n"; 
    
    }                    
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
        print "\n - Dedicated root SSH keys generation\n";
        system("ssh-keygen -q -t rsa -N '' -f /root/.ssh/kanopya_rsa");
    } else {
        print "\n - Dedicated root SSH keys already exists, skipping generation\n";
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

    # kanopya user creation
    my $query = "use mysql; SELECT user FROM mysql.user WHERE user='kanopya' LIMIT 1;";
    my $output = `mysql -h $host -P $port -u root -p$passwd -e "$query"`;
    if ($output !~ /kanopya/) {
        print " - Creating kanopya mysql user\n";
        $query = "CREATE USER 'kanopya'\@'localhost' IDENTIFIED BY '$userpasswd'";
        $output = `mysql -h $host  -P $port -u root -p$passwd -e "$query"`;
    }
    else {
        print " - Mysql kanopya user already exists\n";
    }

    # kanopya user privileges
    print " - Granting all privileges on kanopya database to kanopya user\n";
    $query = "GRANT ALL PRIVILEGES ON kanopya.* TO 'kanopya' WITH GRANT OPTION";
    $output = `mysql -h $host -P $port -u root -p$passwd -e "$query"`;

    # schema creation
    print " - Create kanopya database...";
    system("mysql -h $host  -P $port -u kanopya -p$userpasswd < $self->{dbschema_path}/schemas/Schemas.sql");
    print "ok\n";

    # components schema 
    print " - Create components schemas...";
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
    require PopulateDB;
    print " - Populate database...";
    populateDB(login    => 'admin',
               password => $self->{parameters_values}->{mysql_kanopya_passwd},
               %datas);
    print "ok\n";
}

=pod

=begin classdoc

Configure dhcpd

=end classdoc

=cut

sub _configure_dhcpd {
    my ($self) = @_;
    print " - Dhcpd reconfiguration\n";
    my $configfile = '/etc/dhcp/dhcpd.conf';
    open(my $FILE, '>', $configfile) or die "$!\n";
    print $FILE "ddns-update-style none;\n" .
                "default-lease-time 600;\n" .
                "max-lease-time 7200;\n" .
                "log-facility local7;\n" .
                'subnet ' . $self->{parameters_values}->{admin_net_ip} . ' ' .
                'netmask ' . $self->{parameters_values}->{admin_net_mask} . "{}\n";
    close($FILE);
}

=pod

=begin classdoc

Configure atftpd

=end classdoc

=cut

sub _configure_atftpd {
    my ($self) = @_;
    print " - Atftpd reconfiguration\n";
    my $configfile = '/etc/default/atftpd';
    open(my $FILE, '>', $configfile) or die "$!\n";
    print $FILE "USE_INETD=false\n" .
                "OPTIONS=\"--daemon --tftpd-timeout 300 " .
                "--retry-timeout 5 --no-multicast " .
                "--bind-address ".$self->{parameters_values}->{admin_ip}." ".
                "--maxthread 100 --verbose=5 " .
                "--logfile=/var/log/tftp.log ".$self->{parameters_values}->{tftp_dir}."\"";
    close($FILE);
}

=pod

=begin classdoc

Configure iscsitarget

=end classdoc

=cut

sub _configure_iscsitarget {
    my ($self) = @_;
    print " - Iscsitarget reconfiguration\n";
    my $configfile = '/etc/iet/ietd.conf';
    open(my $FILE, '>', $configfile) or die "$!\n";
    print $FILE "";
    close($FILE);
    
    $configfile = '/etc/default/iscsitarget';
    open($FILE, '>', $configfile) or die "$!\n";
    print $FILE "ISCSITARGET_ENABLE=true";
    close($FILE);
}

=pod

=begin classdoc

Configure rabbitmq

=end classdoc

=cut

sub _configure_rabbitmq {
    my ($self) = @_;
    print " - Rabbitmq configuration\n";

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
}

=pod

=begin classdoc

Configure snmpd

=end classdoc

=cut

sub _configure_snmpd {
    my ($self) = @_;
    print " - Snmpd reconfiguration\n";
    my $template_config = {
        INCLUDE_PATH => $self->{installpath}.'/templates/components/snmpd',
        INTERPOLATE  => 1,
        POST_CHOMP   => 1,
        EVAL_PERL    => 1,
    };

    my $template = Template->new($template_config);
    $template->process('snmpd.conf.tt',
                       { internal_ip_add => $self->{parameters_values}->{admin_ip} },
                       '/etc/snmp/snmpd.conf') ||
            die $template->error(), "\n";

    $template->process('default_snmpd.tt',
                       { internal_ip_add => $self->{parameters_values}->{admin_ip} },
                       '/etc/default/snmpd') ||
            die $template->error(), "\n";
}

=pod

=begin classdoc

Configure puppetmaster

=end classdoc

=cut

sub _configure_puppetmaster {
    my ($self) = @_;
    print " - Puppet master reconfiguration\n";
    my $template_config = {
        INCLUDE_PATH => $self->{installpath} . '/templates/components/puppetmaster',
        INTERPOLATE  => 1,
        POST_CHOMP   => 1,
        EVAL_PERL    => 1,
    };

    my $template = Template->new($template_config);
    $template->process('puppet.conf.tt',
                       { kanopya_puppet_modules =>
                             $self->{installpath} . '/templates/components/puppetmaster/modules'
                       },
                       '/etc/puppet/puppet.conf') ||
            die $template->error(), "\n";

    $template->process('fileserver.conf.tt',
                   { domainname           => $self->{parameters_values}->{domainname},
                     clusters_directories => $self->{parameters_values}->{clusters_dir},
                    },
                   '/etc/puppet/fileserver.conf') ||
        die $template->error(), "\n";
}

=pod

=begin classdoc

Retrieve tftp files from download.kanopya.org

=end classdoc

=cut

sub _retrieve_tftp_content {
    my ($self) = @_;

    my $rsync_sshkey = '~/.ssh/rsync_rsa';
    # Check if rsync sshkey exist on right place :
    if ( ! -e $rsync_sshkey) {
        # Get the rsync_rsa key :
        system('wget http://download.kanopya.org:8011/rsync_rsa');
        # Move the key and set the correct rights ;
        system('mv rsync_rsa ~/.ssh/;chmod 400 ~/.ssh/rsync_rsa');
    }
    # Do a Rsync from download.kanopya.org of tftp directory content :
    system('rsync -var -e "ssh -p 2211 -i /root/.ssh/rsync_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" rsync@download.kanopya.org:/pub/tftp/* '.$self->{parameters_values}->{tftp_dir});
}

=pod

=begin classdoc

Restart middleware processes

=end classdoc

=cut

sub _restart_middlewares {
    my ($self) = @_;
    for my $service ('isc-dhcp-server','iscsitarget','puppetmaster','atftpd','snmpd', 'rabbitmq-server') {
        system("service $service restart");
    }
}

=pod

=begin classdoc

Start kanopya processes

=end classdoc

=cut

sub _start_kanopya_services {
    my ($self) = @_;
    for my $service (@{$self->{kanopya_services}}) {
        system("service $service start");
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
    $self->_create_kanopya_account();
    $self->_create_directories();
    $self->_generate_kanopya_conf();
    $self->_generate_ssh_key();
    $self->_create_database();

    $self->_configure_dhcpd();
    $self->_configure_atftpd();
    $self->_configure_snmpd();
    $self->_configure_iscsitarget();
    $self->_configure_puppetmaster();
    $self->_configure_rabbitmq();

    # copy logrotate file
    copy($self->{installpath}.'/scripts/install/templates/logrotate-kanopya', '/etc/logrotate.d') || die "$!";

    # copy syslog-ng config
    copy($self->{installpath}.'/scripts/install/templates/syslog-ng.conf', '/etc/syslog-ng') || die "$!";

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



#   - /etc/iscsi/initiatorname.iscsi


# 24 write /etc/hosts
# restart des services kanopya


1;
