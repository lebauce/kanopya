#!/usr/bin/perl -W
# init.pl -

#    Copyright © 2011 Hedera Technology SAS
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
# Created 14 july 2010
#This scripts has to be executed as root or with sudo, after Kanopya's installation through a package manager.
#it's goal is to generate configuration files, to create kanopya system user and then to populate the database.
#@Date: 23/02/2011

use strict;

use POSIX;
use File::Path qw(make_path);
use File::Copy;
use File::Find;

use Term::ReadKey;
use Template;
use NetAddr::IP;
use XML::Simple;
use Date::Simple (':all');

BEGIN {
    use File::Basename;
    push @INC, dirname(__FILE__);
}

die "You must be root to execute this scipts" if ( $< != 0 );

#Scripts variables, used to set stuff like path, users, etc
my $install_conf = XMLin("/opt/kanopya/scripts/install/init_struct.xml");
my $questions    = $install_conf->{questions};
my $conf_vars    = $install_conf->{general_conf};
my $conf_default = $install_conf->{default_conf};
my $conf_files   = $install_conf->{genfiles};
my $answers      = {};

my %param_test = (
    dbuser                     => \&matchRegexp,
    dbpassword1                => sub {},
    dbpassword2                => \&comparePassword,
    dbip                       => \&checkIpOrHostname,
    dbport                     => \&checkPort,
    kanopya_server_domain_name => \&matchRegexp,
    internal_net_interface     => \&matchRegexp,
    internal_net_add           => \&checkIp,
    internal_net_mask          => \&checkIp,
    internal_net_pool_range    => \&matchRegexp,
    internal_net_pool_first    => \&checkIp,
    internal_net_pool_gateway  => \&checkIp,
    dmz_net_add                => \&checkIp,
    dmz_net_mask               => \&checkIp,
    log_directory              => \&matchRegexp,
    vg                         => \&matchRegexp,
);

my $line;
my $FILE;
my $debian_version = '';
eval {
    open ($FILE, "<","/etc/debian_version") or die "error while opening /etc/debian_version: $!";
    while ($line = <$FILE>){
        if ($line =~ m/^6\./ || $line =~ m/^squeeze/) {
                print 'stable release: ' . $line . "\n";
                $debian_version = 'squeeze';
        }
        elsif ($line =~ m/^5\./ || $line =~ m/^lenny/) {
                print 'old release: ' . $line . "\n";
                $debian_version = 'lenny';
        }
    }
    close ($FILE);
};

#Welcome message - accepting Licence is mandatory
welcome();
#Ask questions to users
getConf();
#Function used to generate conf files
$answers->{crypt_salt} = join '', ('.','/',0..9,'A'..'Z','a'..'z')[rand 64, rand 64];
genConf();

# creating the graph directory to avoid bug in createUser function
make_path("/tmp/monitor/graph", { verbose => 1 });

#create a user for kanopya
createUser();

###############
#Network setup#
###############
#print "calculating the first host address available for this network...";
#my $internal_ip_add = NetAddr::IP->new($answers->{internal_net_add}, $answers->{internal_net_mask});
#my @c               = split("/",$internal_ip_add->first);
#$internal_ip_add    = $c[0];

my $internal_ip_add = $answers->{internal_net_pool_first};

print "done (first host address is $internal_ip_add)\n";
print "setting up $answers->{internal_net_interface} ...";

system ("ifconfig $answers->{internal_net_interface} $internal_ip_add") == 0 or die "an error occured while trying to set up nic ($answers->{internal_net_interface}) address: $!";

# generate /etc/network/interfaces
if ($debian_version) {
    my $interfaces = "# This file describes the network interfaces available on your system\n";
    $interfaces   .= "# and how to activate them. For more information, see interfaces(5).\n\n";
    $interfaces   .= "# -- generated by Kanopya init.pl script --\n\n";
    $interfaces   .= "auto lo\niface lo inet loopback\n\n";
    $interfaces   .= "auto $answers->{internal_net_interface}\niface $answers->{internal_net_interface} inet static\n";
    $interfaces   .= "\taddress $internal_ip_add\n\tnetmask $answers->{internal_net_mask}\n\n";
    $interfaces   .= "# -- end of Kanopya init.pl script generation --\n";
    writeFile('/etc/network/interfaces', $interfaces);
    print "done\n";
}
else {
    print "Skipping network configuration";
}

#We gather the NIC's MAC address
my $internal_net_interface_mac_add = `ip link list dev $answers->{internal_net_interface} | egrep "ether [0-9a-zA-Z]{2}:[0-9a-zA-Z]{2}:[0-9a-zA-Z]{2}:[0-9a-zA-Z]{2}:[0-9a-zA-Z]{2}:[0-9a-zA-Z]{2}" | cut -d' ' -f6`;
chomp($internal_net_interface_mac_add);

#######################
# VG Analysis
#We gather the vg's size and free space:
my $kanopya_vg_sizes = `vgs --noheadings $answers->{vg} --units B -o vg_size,vg_free --nosuffix --separator '|'`;
chomp($kanopya_vg_sizes);
$kanopya_vg_sizes =~ s/^\s+//;
my ( $kanopya_vg_size, $kanopya_vg_free_space ) = split(/\|/,$kanopya_vg_sizes);

#We gather pv's present in the vg
my @kanopya_pvs = `pvs --noheadings --separator '|' -o pv_name,vg_name  | grep $answers->{vg} | cut -d'|' -f1`;
chomp(@kanopya_pvs);

#########################
#Directory manipulations#
#########################

# logs directory creation

print "creating the logging directory...";
$answers->{log_directory} .= '/' if($answers->{log_directory} !~ /\/$/);
make_path("$answers->{log_directory}", { verbose => 1, mode => 0757 });
make_path("$answers->{log_directory}workflows", { verbose => 1, mode => 0757 });
# Give write access to nobody /!\ TEMPORARY
print "done\n";

# master images directory creation
print "creating the master images directory...";
$answers->{masterimages_directory} .= '/' if($answers->{masterimages_directory} !~ /\/$/ );
make_path("$answers->{masterimages_directory}", { verbose => 1, mode => 0755 });
print "done\n";

# tftp directory creation
print "creating the tftp directory...";
$answers->{tftp_directory} .= '/' if($answers->{tftp_directory} !~ /\/$/ );
make_path("$answers->{tftp_directory}", { verbose => 1, mode => 0755 });
print "done\n";

# clusters directory creation
print "creating the clusters directory...";
$answers->{clusters_directory} .= '/' if($answers->{clusters_directory} !~ /\/$/);
make_path("$answers->{clusters_directory}", { verbose => 1, mode => 0755 });
print "done\n";

# /nfsexports directory creation
make_path('/nfsexports', { verbose => 1 });

######################
# SSH key generation #
######################
if((! -e '/root/.ssh/kanopya_rsa') && (! -e '/root/.ssh/kanopya_rsa.pub')) {
    make_path('/root/.ssh', { verbose => 1 }) if ( ! -e '/root/.ssh' );

  system("ssh-keygen -q -t rsa -N '' -f /root/.ssh/kanopya_rsa");
  print "New SSH keys generated for kanopya\n";
}

########################
#Services configuration#
########################
#We configure dhcp server with the gathered informations
#As conf file changes from lenny to squeeze, we need to handle both cases

my $dhcp_config = '/etc/dhcp/dhcpd.conf';

if ($debian_version eq 'lenny') {
    $dhcp_config = '/etc/dhcp3/dhcpd.conf';
}

writeFile($dhcp_config, "ddns-update-style none;\n" .
                        "default-lease-time 600;\n" .
                        "max-lease-time 7200;\n" .
                        "log-facility local7;\n" .
                        'subnet ' . $answers->{internal_net_add} . ' ' .
                        'netmask ' . $answers->{internal_net_mask} . "{}\n");

service([ 'dhcpd', 'isc-dhcp-server' ], 'restart');

# Atftpd configuration
writeFile('/etc/default/atftpd', "USE_INETD=false\n" .
                                 "OPTIONS=\"--daemon --tftpd-timeout 300 " .
                                 "--retry-timeout 5 --no-multicast " .
                                 "--bind-address $internal_ip_add " .
                                 "--maxthread 100 --verbose=5 " .
                                 "--logfile=/var/log/tftp.log $answers->{tftp_directory}\"");

########################
#Database configuration#
########################

# first test if mysql server is running
my $mysqlpidfile = '/var/run/mysqld/mysqld.pid';
service([ "mysql" ], 'start') if ( ! -e $mysqlpidfile );

my ( $sysname, $nodename, $release, $version, $machine ) = POSIX::uname();

my $date = today();
my $year = $date->year;
my $month = $date->month;

if (length ($month) == 1) {
    $month = '0' . $month;
}

my $hostname = `hostname`;
chomp($hostname);

my $domain = $answers->{kanopya_server_domain_name};

my $kanopya_initiator = "iqn.$year-$month." 
    . join('.', reverse split(/\./, $domain)) .':'.time();

################We generate the Data.sql file and setup database
my %datas = (
    kanopya_vg_name          => $answers->{vg},
    kanopya_vg_size          => $kanopya_vg_size,
    kanopya_vg_free_space    => $kanopya_vg_free_space,
    kanopya_pvs              => \@kanopya_pvs,
    poolip_addr              => $internal_ip_add,
    poolip_netmask           => $answers->{internal_net_mask},
    poolip_mask              => $answers->{internal_net_pool_range},
    poolip_gateway           => $answers->{internal_net_pool_gateway},
    ipv4_internal_network_ip => $answers->{internal_net_add},
    admin_domainname         => $answers->{kanopya_server_domain_name},
    kanopya_hostname         => $hostname,
    kanopya_initiator        => $kanopya_initiator,
    mb_hw_address            => $internal_net_interface_mac_add,
    admin_interface          => $answers->{internal_net_interface},
    admin_password           => $answers->{dbpassword1},
    admin_kernel             => $release,
    tmstp                    => time(),
    masterimages_directory   => $answers->{masterimages_directory},
    clusters_directory       => $answers->{clusters_directory},
    tftp_directory           => $answers->{tftp_directory},
);

useTemplate(
    template => 'Data.sql.tt',
    datas    => \%datas,
    conf     => $conf_vars->{data_sql},
    include  => $conf_vars->{data_dir}
);

useTemplate(
    template => "initiatorname.iscsi.tt",
    datas    => \%datas,
    conf     => "/etc/iscsi/initiatorname.iscsi",
    include  => $conf_vars->{install_template_dir}
);

###############Creation of database user
my $root_passwd;
print "Please enter your root database user password :\n";
ReadMode('noecho');
chomp($root_passwd = <STDIN>);
ReadMode('original');
#Test user for creation
my $user = `mysql -h $answers->{dbip}  -P $answers->{dbport} -u root -p$root_passwd -e "use mysql; SELECT user FROM mysql.user WHERE user='$answers->{dbuser}';" | grep "$answers->{dbuser}"`;
if (!$user) {
    print "creating mysql user, please insert root password...\n";
    system ("mysql -h $answers->{dbip}  -P $answers->{dbport} -u root -p$root_passwd " .
            "-e \"CREATE USER '" . $answers->{dbuser} . "'\@'localhost' " .
            "IDENTIFIED BY '$answers->{dbpassword1}'\"") == 0 or die "error while creating mysql user: $!" == 0 or die "error while creating mysql user: $!";
    eval {
        system ("mysql -h $answers->{dbip}  -P $answers->{dbport} -u root -p$root_passwd -e \"CREATE USER '$answers->{dbuser}' IDENTIFIED BY '$answers->{dbpassword1}'\"");
    };
    print "done\n";
}
else {
    print "User $answers->{dbuser} already exists\n";
}

#We grant all privileges to kanopya database for $db_user
#my $grant = `mysql -h $answers->{dbip}  -P $answers->{dbport} -u root -p$root_passwd -e "use mysql; SHOW GRANTS for $answers->{dbuser};" | grep kanopya\.`;
print "granting all privileges on kanopya database to $answers->{dbuser}, please insert root password...\n";
system ("mysql -h $answers->{dbip} -P $answers->{dbport} -u root -p$root_passwd -e \"GRANT ALL PRIVILEGES ON kanopya.* TO '$answers->{dbuser}' WITH GRANT OPTION\"") == 0 or die "error while granting privileges to $answers->{dbuser}: $!";
print "done\n";

#We now generate the database schemas
print "generating database schemas...";
system ("mysql -h $answers->{dbip}  -P $answers->{dbport} -u $answers->{dbuser} -p$answers->{dbpassword1} < $conf_vars->{schema_sql}") == 0 or die "error while generating database schema: $!";
print "done\n";
#We now generate the components schemas
print "loading component DB schemas...";
open ($FILE, "<","$conf_vars->{comp_conf}") or die "error while opening components.conf: $!";

while( defined( $line = <$FILE> ) )
{
    chomp ($line);
    # don't proceed empty lines or commented lines
    next if (( ! $line ) || ( $line =~ /^#/ ));
    print "installing $line component in database from $conf_vars->{comp_schemas_dir}$line.sql...\n ";
    system("mysql -u $answers->{dbuser} -p$answers->{dbpassword1} < $conf_vars->{comp_schemas_dir}$line.sql");
    print "done\n";
}
close($FILE);
print "components DB schemas loaded\n";
#And to conclude, we insert initial datas in the DB
print "inserting initial data...";
system ("mysql -u $answers->{dbuser} -p$answers->{dbpassword1} < $conf_vars->{data_sql}") == 0 or die "error while inserting initial data: $!";
print "done\n";

# Populate DB with more data (perl script instead of sql)
print "populate database...";
require PopulateDB;
populateDB(login    => $answers->{dbuser},
           password => $answers->{dbpassword1},
           %datas);
print "done\n";

#######################
#Services manipulation#
#######################
# We change the syslog-ng configuration and restart the service
copy("$conf_vars->{install_template_dir}/syslog-ng.conf", '/etc/syslog-ng') || die "Copy failed $!";
service([ "syslog-ng" ], 'restart');

# We remove the initial tftp line from inetd conf file and restart the service
if ($debian_version) {
    deleteLine(qr/^tftp.*/, '/etc/inetd.conf');
    service([ 'inetutils-inetd' ], 'restart');
}

# We restart atftpd with the new configuration
service([ 'atftpd', 'xinetd' ], 'restart');

if ($debian_version) {
    writeFile('/etc/iet/ietd.conf', '');
    writeFile('/etc/default/iscsitarget', "ISCSITARGET_ENABLE=true");

    service([ 'iscsitarget', 'iscsid' ], 'restart');
}

my $templateslink = '/templates';
if (not -e $templateslink) {
    eval {
        symlink('/opt/kanopya/templates', $templateslink);
    };

    print "Your system does not support symbolic links", "\n" if $@;
}

# We allow snmp access
useTemplate(
    template => "snmpd.conf.tt",
    datas    => {
        internal_ip_add => $internal_ip_add
    },
    conf     => "/etc/snmp/snmpd.conf",
    include  => $conf_vars->{install_template_dir}
);

if ($debian_version) {
    useTemplate(
        template => "snmpd_default.tt",
        datas    => {
            internal_ip_add => $internal_ip_add
        },
        conf     => $debian_version ? "/etc/default/snmpd" : "/etc/sysconfig/snmp",
        include  => $conf_vars->{install_template_dir}
    );
}

service([ 'snmpd' ], 'restart');

# Dancer configuration
useTemplate(
    template => "dancer_cfg.tt",
    datas    => {
       log_directory    => $answers->{log_directory},
       product          => $conf_default->{product},
       show_gritters    => $conf_default->{product} eq 'KIO' ? 0 : 1
    },
    conf     => "/opt/kanopya/ui/Frontend/config.yml",
    include  => $conf_vars->{install_template_dir}
);

# Puppetmaster configuration
generatePuppetConfiguration(%datas);

# Configure log rotate
copy("$conf_vars->{install_template_dir}/logrotate-kanopya", '/etc/logrotate.d') || die "Copy failed $!";

# set /etc/hosts
writeFile('/etc/hosts', "127.0.0.1 localhost\n$internal_ip_add $hostname.$domain $hostname\n");

# Launching Kanopya's init scripts
service([ 'kanopya-executor' ], 'restart');
service([ 'kanopya-state-manager' ], 'restart');
service([ 'kanopya-aggregator' ], 'restart');
service([ 'kanopya-collector' ], 'restart');
service([ 'kanopya-rulesengine' ], 'restart');
service([ 'kanopya-front' ], 'restart');

print "\ninitial configuration: done.\n";
print "You can now visit http://$internal_ip_add:5000 and start using Kanopya!\n";
print "To Connect to Kanopya web use :\n";
print "user : <admin>\n";
print "password : <$answers->{dbpassword1}>\n";

# Prepare /tftp :
print "Populate $answers->{tftp_directory} directory.\n";
tftpPopulation();

##########################################################################################
##############################FUNCTIONS DECLARATION#######################################
##########################################################################################
sub welcome {
    my $validate_licence;

    print "Welcome on Kanopya\n";
    print "This script will configure your Kanopya instance\n";
    print "We advise to install Kanopya instance on a dedicated server\n";
    print "First please validate the user licence\n";
    getLicence();
    print "Do you accept the licence ? (y/n)\n";
    chomp($validate_licence= <STDIN>);
    exit 1 if ( $validate_licence ne 'y' );
    print "Please answer to the following questions\n";
}

sub getLicence {
    open (my $LICENCE, "<", "/opt/kanopya/UserLicence")
        or die "error while opening UserLicence: $!";
    while (<$LICENCE>) {
        print;
    }
    close($LICENCE);
}

######################################### Methods to prompt user for informations
sub getConf{
    my $i = 0;
    foreach my $question (sort keys %$questions){
        print "question $i : ". $questions->{$question}->{question} . " (". $questions->{$question}->{default} .")\n";

        # Secret activation
        ReadMode('noecho') if ( defined $questions->{$question}->{'is_secret'} );
        my @searchable_answer;
        # if answer is searchable and has an answer detection, allow user to choose good answer
        if ($questions->{$question}->{is_searchable} eq "n"){
            my $tmp = `$questions->{$question}->{search_command}`;
            chomp($tmp);
            @searchable_answer = split(/ /, $tmp);
            my $cpt = 0;
            print "Choose a value between the following :\n";
            for my $possible_answer (@searchable_answer) {
                print "\n[$cpt] $possible_answer\n";
                $cpt++;
            }
        }
        chomp($answers->{$question} = <STDIN>);

        if ($answers->{$question} eq ''){
            if ($questions->{$question}->{is_searchable} eq "1"){
                print "Script will discover your configuration\n";
                $answers->{$question} = `$questions->{$question}->{search_command}`;
            } else {
                if ($questions->{$question}->{is_searchable} eq "n"){
                    $answers->{$question} = 0;
                }
                else {
                #print "Use default value\n";
                $answers->{$question} = $questions->{$question}->{default};}
            }
            chomp($answers->{$question});
        }
        else {
            my $method = $param_test{$question} || \&noMethodToTest;
            while ($method->(question => $question)){
                print "Wrong value, try again\n";
                chomp($answers->{$question} = <STDIN>);
            }
        }
        if ($questions->{$question}->{is_searchable} eq "n"){
            if ($answers->{$question} >= scalar @searchable_answer) {
                print "Error you entered a value out of the answer scope.";
                default_error();
            }
            else {
                # On transforme la valeur de l'utilisateur par celle de la selection proposee
                $answers->{$question} = $searchable_answer[$answers->{$question}];
            }
        }
        # Secret deactivation
        ReadMode('original') if ( defined $questions->{$question}->{'is_secret'} );
        $i++;
        print "\n";
    }
}

sub writeFile {
    my ( $path_file, $line ) = @_;

    open (my $FILE, ">", $path_file)
        or die "an error occured while opening $path_file: $!";
    print $FILE $line;
    close($FILE);
}

sub chownRecursif {
    my ( $user_name, $directory ) = @_;

    my ( $user, $pass, $uid, $gid ) = getpwnam($user_name);

    find(
        sub {
            chown $uid, $gid, $_
                or die "Could not chown '$_': $!";
        },
        $directory
    );
}

sub deleteLine {
    my ( $regex, $path_file ) = @_;

    my $tmp_file_name = $path_file . 'tmp';

    open(my $FILE, "<", $path_file) or die "an error occured while opening $path_file : $!";
    open(my $TMP, ">", $tmp_file_name) or die "an error occured while opening $tmp_file_name : $!";

    while (<$FILE>) {
        print $TMP unless m/$regex/;
    }

    close($FILE);
    close($TMP);

    rename($tmp_file_name, $path_file)
}

sub matchRegexp{
    my %args = @_;

    if ((!defined $args{question} or !exists $args{question})){
        print "Error, did you modify init script ?\n";
        exit 1;
    }

    default_error() if ( ! defined $questions->{$args{question}}->{pattern} );

    if($answers->{$args{question}} !~ m/($questions->{$args{question}}->{pattern})/){
        print "answer <".$answers->{$args{question}}."> does not fit regexp <". $questions->{$args{question}}->{pattern}.">\n";
        return 1;
    }

    return 0;
}

######################################### Methods to check user's parameter

sub checkPort{
    my %args = @_;

    if ((!defined $args{question} or !exists $args{question})){
        print "Error, Do you modify init script ?\n";
        exit 1;
    }
    if ($answers->{$args{question}} !~ m/\d+/) {
        print "port has to be a numerical value\n";
        return 1;
    }
    if (!($answers->{$args{question}} >0 and $answers->{$args{question}} < 65535)) {
        print "port has to have value between 0 and 65535\n";
        return 1;
    }

    return 0;
}

# Check ip or hostname
# Hostname could only be localhost for the moment
sub checkIpOrHostname{
    my %args = @_;

    if ((!defined $args{question} or !exists $args{question})){
        default_error();
    }

    if ($answers->{$args{question}} =~ m/localhost/) {
        $answers->{$args{question}} = "127.0.0.1";
    }
    else {
        return checkIp(%args);
    }

    return 0;
}

sub checkIp{
    my %args = @_;

    my $ip = new NetAddr::IP($answers->{$args{question}});

    if ((!defined $args{question} or !exists $args{question})) {
        default_error();
    }

    if(not defined $ip) {
        print "IP <".$answers->{$args{question}}."> seems to be not good";
        return 1;
    }

    return 0;
}

# Check that password is confirmed
sub comparePassword {
    my %args = @_;

    if ((!defined $args{question} or !exists $args{question})){
        default_error();
    }

    if ($answers->{$args{question}} ne $answers->{'dbpassword1'}){
        print "Passwords are differents\n";
        return 1;
    }

    ReadMode('original');

    return 0;
}

# When no check method are defined in param_test structure.
sub noMethodToTest {
    print "Error, param get not found in test table.\n";
    print "If you modified your init script or its xml, you may have broken your install";
    exit 1;
}

# Default error message and exit
sub default_error {
    print "Error, did you modify init script ?\n";
    exit 1;
}

# Method for populate tftp directory
sub tftpPopulation {
    
    my $rsync_sshkey = '~/.ssh/rsync_rsa';
    # Check if rsync sshkey exist on right place :
    if ( ! -e $rsync_sshkey) {
        # Get the rsync_rsa key :
        system('wget http://download.kanopya.org:8011/rsync_rsa');
        # Move the key and set the correct rights ;
        system('mv rsync_rsa ~/.ssh/;chmod 400 ~/.ssh/rsync_rsa');
    }
    # Do a Rsync from download.kanopya.org of tftp directory content :
    system('rsync -var -e "ssh -p 2211 -i /root/.ssh/rsync_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" rsync@download.kanopya.org:/pub/tftp/* '.$answers->{tftp_directory});
}

sub generatePuppetConfiguration {
    my %args = @_;

    useTemplate(
        include  => '/opt/kanopya/templates/components/puppetmaster',
        template => 'puppet.conf.tt',
        conf     => '/etc/puppet/puppet.conf',
        datas    => {
            kanopya_puppet_modules => '/opt/kanopya/templates/components/puppetmaster/modules',
            admin_domainname       => $args{admin_domainname},
            kanopya_hostname       => $args{kanopya_hostname}
        }
    );

    my $path = $answers->{clusters_directory};
    if($path =~ /\/$/) {
        chop($path);
    }

    useTemplate(
        include  => '/opt/kanopya/templates/components/puppetmaster',
        template => 'fileserver.conf.tt',
        conf     => '/etc/puppet/fileserver.conf',
        datas    => {
            domainname         => $args{admin_domainname},
            clusters_directory => $path,
        }
    );

    useTemplate(
        include  => '/opt/kanopya/templates/components/puppetagent',
        template => 'default_puppet.tt',
        conf     => '/etc/default/puppet',
        datas    => {
            puppetagent2_bootstart => "yes"
        }
    );

    writeFile('/etc/puppet/manifests/site.pp',
              "stage { 'system': before => Stage['main'], }\n" .
              "import \"nodes/*.pp\"\n");

    use Kanopya::Config;
    use EEntity;

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

    system([ 'puppet' ], 'restart');
    system([ 'puppetmaster' ], 'restart');
}


###################################################### Following functions generates conf files for Kanopya

sub genConf {
    mkdir $conf_vars->{conf_dir} unless ( -d $conf_vars->{conf_dir} );
    `mkdir -p $conf_vars->{rrd_dir}` unless ( -d $conf_vars->{rrd_dir} );

    my %datas;
    foreach my $files (keys %$conf_files){
        foreach my $d (keys %{$conf_files->{$files}->{datas}}){
            $datas{$d} = $answers->{$conf_files->{$files}->{datas}->{$d}};
        }
        useTemplate(
            template => $conf_files->{$files}->{template},
            datas    => \%datas,
            conf     => $conf_vars->{conf_dir} . $files,
            include  => $conf_vars->{install_template_dir}
        );
    }
}

sub createUser {
    system("useradd kanopya -r -c 'Kanopya User' -s '/bin/false' -b '/opt'");
    make_path("/tmp/kanopya-sessions", { verbose => 1 });
    chownRecursif('kanopya', '/tmp/kanopya-sessions');
    chownRecursif('kanopya', '/opt/kanopya');
    chmod 0775, '/opt/kanopya';
}

sub useTemplate {
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

sub service {
    my ($services, $command) = @_;
    if ($debian_version) {
        for my $service (@{$services}) {
            system("invoke-rc.d " . $service . " " . $command);
        }
    }
    else {
        for my $service (@{$services}) {
            system("service " . $service . " " . $command);
        }
    }
}
