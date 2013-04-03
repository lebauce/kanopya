# winsetup.pl -

#    Copyright © 2012, 2013, 2014 Hedera Technology SAS
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
# Created 16 february 2012

use strict;
use warnings;
use Data::Dumper;
use Template;
use XML::Simple;
use Term::ReadKey;
use Path::Class;


#get Kanopya directory
my $infos       = getKanopyaDirectory();
my $kanopya_dir = $infos->{kanopya_dir};
my $base_dir    = $infos->{base_dir};

#generic variables used through the script
my $install_conf = XMLin("$base_dir/wininit_struct.xml");
my $conf_vars    = $install_conf->{general_conf};

while (my ($key,$path) = each %$conf_vars) {
    $conf_vars->{$key} = $kanopya_dir.$path;
}

my $conf_default    = $install_conf->{default_conf};
my $conf_files      = $install_conf->{genfiles};
my $service_dir     = $conf_vars->{services_dir};
my $services        = $install_conf->{services};

my $log_directory    = 'C:\var\log\kanopya\\';
my $tmp_monitor      = 'C:\tmp\monitor\graph\\';
my $tmp_orchestrator = 'C:\tmp\orchestrator\graph\\';
my $timedata_dir     = 'C:\tmp\monitor\TimeData\\';

my $crypt_salt = join '', ('.','/',0..9,'A'..'Z','a'..'z')[rand 64, rand 64];

my %conf_data = (
    logdir                     => $log_directory,
    internal_net_add           => '10.0.1.0',
    internal_net_mask          => '255.255.255.0',
    dmz_net_add                => '10.0.11.0',
    dmz_net_mask               => '255.255.255.0',
    db_user                    => 'kanopya',
    dbport                     => '3306',
    dbip                       => '127.0.0.1',
    admin_password             => 'K4n0pY4', 
    kanopya_server_domain_name => 'kanopya.localdomain',
    db_name                    => 'kanopya',
    db_pwd                     => 'K4n0pY4',
    crypt_salt		           => $crypt_salt,
);

#Welcome message - accepting Licence is mandatory
welcome();

#generation of configuration files
genConf();

###########################
#Environment configuration#
###########################

#init PERL5LIB
print 'initialazing PERL5LIB'."\n";
my $cmd = qq[setx PERL5LIB "$kanopya_dir\\kanopya\\lib\\common;$kanopya_dir\\kanopya\\lib\\administrator;$kanopya_dir\\kanopya\\lib\\executor;$kanopya_dir\\kanopya\\lib\\monitor;$kanopya_dir\\kanopya\\lib\\orchestrator;$kanopya_dir\\kanopya\\lib\\external;$kanopya_dir\\kanopya\\lib\\external\\NetApp;$kanopya_dir\\kanopya\\lib\\component\\kanopya_front;$kanopya_dir\\kanopya\\lib\\component\\kanopya_executor;$kanopya_dir\\kanopya\\lib\\component\\kanopya_aggregator;$kanopya_dir\\kanopya\\lib\\component\\kanopya_rulesengine"];
print $cmd."\n";
my $exec = `$cmd 2>&1`;

#lol.
push @INC, ("$kanopya_dir" . 'kanopya\lib\common',
            "$kanopya_dir" . 'kanopya\lib\administrator',
            "$kanopya_dir" . 'kanopya\lib\executor',
            "$kanopya_dir" . 'kanopya\lib\monitor',
            "$kanopya_dir" . 'kanopya\lib\orchestrator',
            "$kanopya_dir" . 'kanopya\lib\external',
            "$kanopya_dir" . 'kanopya\lib\external\NetApp',
            "$kanopya_dir" . 'kanopya\lib\component\kanopya_front',
            "$kanopya_dir" . 'kanopya\lib\component\kanopya_executor',
            "$kanopya_dir" . 'kanopya\lib\component\kanopya_aggregator',
            "$kanopya_dir" . 'kanopya\lib\component\kanopya_rulesengine');

######################
#Directories Creation#
######################

sub createDir {
    my ($type, $path) = @_;
    print "creating $type directory\n";
    $cmd = 'mkdir '.$path;
    print $cmd."\n";
    $exec = `$cmd 2>&1`;
    print $exec."\n";
}

createDir('log', $log_directory);
createDir('workflows log', $log_directory.'workflows\\');
createDir('monitor temp', $tmp_monitor);
createDir('orchestrator temp', $tmp_orchestrator);
createDir('time data temp', $timedata_dir);

################
#Database Setup#
################

#Data.sql generation
my @kanopya_pvs = ('kanopya_pv_name');
my %db_data = (
    kanopya_vg_name          => 'vg1',
    kanopya_vg_size          => '100',
    kanopya_vg_free_space    => '90',
    kanopya_pvs              => \@kanopya_pvs,
    ipv4_internal_ip         => '192.168.100.100',
    ipv4_internal_netmask    => $conf_data{internal_net_mask},
    ipv4_internal_network_ip => $conf_data{internal_net_add},
	admin_interface          => 'eth0',
    admin_domainname         => $conf_data{kanopya_server_domain_name},
    mb_hw_address            => 'FF:FF:FF:FF:FF:FF',
    admin_password           => $conf_data{admin_password},
    admin_kernel             => '2.39',
    tmstp                    => time(),
    poolip_addr              => '10.0.0.1',
    poolip_mask              => '256',
    poolip_netmask           => '255.255.255.0',
    poolip_gateway           => '0.0.0.0',
);

print 'generating Data.sql...';

useTemplate(
    template => 'Data.sql.tt',
    datas    => \%db_data,
    conf     => $conf_vars->{data_sql},
    include  => $conf_vars->{data_dir}
);

print 'done'."\n";

print "Please enter your root database user password :\n";
ReadMode('noecho');
chomp(my $root_passwd = <STDIN>);
ReadMode('original');

#Test user for creation
$cmd        = "mysql -h 127.0.0.1 -P 3306 -u root -p$root_passwd -e \"use mysql; SELECT user FROM mysql.user WHERE user='kanopya';\"";
my $user    = `$cmd 2>&1`;
my $db_user = $conf_data{db_user};
my $db_pwd  = $conf_data{db_pwd};
my $dbip    = $conf_data{dbip};
my $dbport  = $conf_data{dbport};
print $user."\n";
if ($user !~ m/$db_user/) {
    print "creating mysql user, please insert root password...\n";
    $cmd = "mysql -h $dbip -P $dbport -u root -p$root_passwd -e \"CREATE USER '$db_user' IDENTIFIED BY '$db_pwd'\"";
    $exec = `$cmd 2>&1`;
    print "done\n";
}
else {
    print "User $db_user already exists\n";
}

#We grant all privileges to kanopya database for $db_user
my $db_name = $conf_data{db_name};

print "granting all privileges on $db_name database to $db_user , please insert root password...\n";
$cmd  = "mysql -h $dbip  -P $dbport -u root -p$root_passwd -e \"GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user' WITH GRANT OPTION\"";
$exec = `$cmd 2>&1`;
print "done\n";

#We now generate the database schemas
print "generating database schemas...";
$cmd  ="mysql -h $dbip  -P $dbport -u $db_user -p$db_pwd < \"$conf_vars->{schema_sql}\"";
$exec = `$cmd 2>&1`;
print "done\n";

#We now generate the components schemas
print "loading component DB schemas...\n";
open (my $FILE, "<","$conf_vars->{comp_conf}");

my $line;
while(defined($line = <$FILE>)) {
    $/ = "\r\n";
    chomp ($line);
    # don't proceed empty lines or commented lines
    next if (( ! $line ) || ( $line =~ /^#/ ));
    print "installing $line component in database from $conf_vars->{comp_schemas_dir}$line.sql..\n";
    $cmd  = "mysql -u $db_user -p$db_pwd < \"$conf_vars->{comp_schemas_dir}$line.sql\"";
    $exec = `$cmd 2>&1`;
    print "done\n";
}
close($FILE);
print "components DB schemas loaded\n";

#We set again the cariage return caracter to \n
$/ = "\n"; 

#And to conclude, we insert initial datas in the DB
#print "inserting initial datas...";
#$cmd  = "mysql -u $db_user -p$db_pwd < \"$conf_vars->{data_sql}\""; 
#$exec = `$cmd 2>&1`;
#print "done\n";

#######################
#Service configuration#
#######################

#gather login and pwd
print 'Gathering Kanopya services informations...'."\n";
my ($login,$pwd);
print 'Please enter your full Kanopya service user:'."\n";
chomp($login = <STDIN>);
print 'Please enter your full Kanopya service password'."\n";
ReadMode('noecho');
chomp($pwd = <STDIN>);
ReadMode('original');

#Install windows services
chop($kanopya_dir);
while (my ($service,$file) = each %$services) {
    print 'installing '."$service ... \n";
    my $cmd = qq[perl.exe "$service_dir$file" -i "$kanopya_dir" $login $pwd];
    eval {
        system($cmd);
    };
    if ($@) {
        print "$service".' failed to be installed. Please launch again setup
               or install the service manually'."\n";
        print $@."\n";
    }
    else {
        my @service_name = split '.pl', $file;
        print 'Launching '. $service_name[0]."...\n";
        my $sc = qq{sc.exe start $service_name[0]};
        eval {
            system($sc);
        };
        if ($@) {
            print 'Error while launching '.$service_name[0]."\n";
            print $@."\n";
        }
    }
}

# Populate DB with more data (perl script instead of sql)
print "populate database...";
require PopulateDB;
populateDB(login    => $db_user,
           password => $db_pwd,
           %db_data);
print "done\n";

# Dancer configuration
useTemplate(
    template => "dancer_cfg.tt",
    datas    => {
       log_directory    => $log_directory,
       product          => $conf_default->{product},
       show_gritters    => $conf_default->{product} eq 'KIO' ? 0 : 1,
    },
    conf     => "$kanopya_dir/kanopya/ui/Frontend/config.yml",
    include  => $conf_vars->{install_template_dir}
);

print q{Congratulations, you've finished Kanopya installation!}."\n";
print q{You can now visit the web interface at the following adress:}."\n";
print q{localhost:5000}."\n";

##########################################################################################
##############################FUNCTIONS DECLARATION#######################################
##########################################################################################

sub welcome {
    my $validate_licence;

    print "Welcome on Kanopya\n";
    print "This script will configure your Kanopya instance\n";
    print "We advise to install Kanopya instance on a dedicated server\n";
    print "First please validate the user licence\n";
    #getLicence();
    print "Do you accept the licence ? (y/n)\n";
    chomp($validate_licence = <STDIN>);
    exit if ($validate_licence ne 'y');
}

sub getLicence {
    open (my $LICENCE, "<", "/opt/kanopya/UserLicence")
        or die "error while opening UserLicence: $!";
    while (<$LICENCE>) {
        print;
    }
    close($LICENCE);
}

sub genConf {
    mkdir $conf_vars->{conf_dir};
    my %datas;
    foreach my $files (keys %$conf_files) {
        foreach my $d (keys %{$conf_files->{$files}->{datas}}) {
            $datas{$d} = $conf_data{$d};
        }
        $datas{windows} = 1;
        useTemplate(
            template => $conf_files->{$files}->{template},
            datas    => \%datas,
            conf     => $conf_vars->{conf_dir} . $files,
            include  => $conf_vars->{install_template_dir}
        );
    }
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

sub getKanopyaDirectory {
    my %infos;

    $infos{base_dir}    = file($0)->absolute->dir;
    my @kanopya         = split 'kanopya', $infos{base_dir};
    $infos{kanopya_dir} = $kanopya[0];

    return \%infos;
}
