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

#generic variables used through the script
my $install_conf = XMLin("/opt/kanopya/scripts/install/wininit_struct.xml");
my $conf_vars    = $install_conf->{general_conf};
my $conf_files   = $install_conf->{genfiles};
my $log_directory = $conf_vars->{log_directory};
my $tmp_monitor = $conf_vars->{tmp_monitor};
my $tmp_orchestrator = $conf_vars->{tmp_orchestrator};
my $timedata_dir = $conf_vars->{timedata_tmp};

my %conf_data = (
    logdir => $log_directory,
    internal_net_add => '10.0.1.0',
    internal_net_mask => '255.255.255.0',
    dmz_net_add => '10.0.11.0',
    dmz_net_mask => '255.255.255.0',
    db_user => 'kanopya',
    dbport => '3306',
    dbip => '127.0.0.1',
    admin_password => 'K4n0pY4', 
    kanopya_server_domain_name => 'hostname',
    db_name => 'administrator',
    db_pwd => 'K4n0pY4',
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
my $cmd = 'setx PERL5LIB "C:\opt\kanopya\ui\lib;C:\opt\kanopya\lib\common;C:\opt\kanopya\lib\administrator;C:\opt\kanopya\lib\executor;C:\opt\kanopya\lib\monitor;C:\opt\kanopya\lib\orchestrator;C:\opt\kanopya\lib\external"';
print $cmd."\n";
my $exec = `$cmd 2>&1`;

print $exec."\n";
print 'You will have to relog to your session to enjoy the configured PERL5LIB'."\n";

######################
#Directories Creation#
######################

print 'creating log directory'."\n";
$cmd = 'mkdir '.$log_directory;
print $cmd."\n";
$exec = `$cmd 2>&1`;
print $exec."\n";

print 'creating monitor temp directory'."\n";
$cmd = 'mkdir '.$tmp_monitor;
print $cmd."\n";
$exec = `$cmd 2>&1`;
print $exec."\n";

print 'creating orchestrator temp directory'."\n";
$cmd = 'mkdir '.$tmp_orchestrator;
print $cmd."\n";
$exec = `$cmd 2>&1`;
print $exec."\n";

print 'creating time data temp directory'."\n";
$cmd = 'mkdir '.$timedata_dir;
print $cmd."\n";
$exec = `$cmd 2>&1`;
print $exec."\n";


################
#Database Setup#
################

#Data.sql generation
my @kanopya_pvs;

my %db_data = (
    kanopya_vg_name          => 'vg1',
    kanopya_vg_size          => '100',
    kanopya_vg_free_space    => '90',
    kanopya_pvs              => \@kanopya_pvs,
    ipv4_internal_ip         => '192.168.100.100',
    ipv4_internal_netmask    => $conf_data{internal_net_mask},
    ipv4_internal_network_ip => $conf_data{internal_net_add},
    admin_domainname         => $conf_data{kanopya_server_domain_name},
    mb_hw_address            => 'FF:FF:FF:FF:FF:FF',
    admin_password           => $conf_data{admin_password},
    admin_kernel             => '2.39',
    tmstp                    => time()
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
# this should have been the classic powershell command to grep kanopya user from the sql request. As it doesn't work in the same way from the perl script, we'll use the method bellow
# my $cmd = "mysql -h 127.0.0.1 -P 3306 -u root -p$root_passwd -e \"use mysql; SELECT user FROM mysql.user WHERE user='kanopya';\" | where {$_ -match \"kanopya\"}";
$cmd = "mysql -h 127.0.0.1 -P 3306 -u root -p$root_passwd -e \"use mysql; SELECT user FROM mysql.user WHERE user='kanopya';\"";
my $user = `$cmd 2>&1`;
my $db_user = $conf_data{db_user};
my $db_pwd = $conf_data{db_pwd};
my $dbip = $conf_data{dbip};
my $dbport = $conf_data{dbport};
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

#We grant all privileges to administrator database for $db_user

$cmd = "mysql -h $dbip  -P $dbport -u root -p$root_passwd -e \"use mysql; SHOW GRANTS for $db_user;\"";
my $grant = `$cmd 2>&1` ;
my $db_name = $conf_data{db_name};
print $grant."\n";
 if ($grant !~ m/$db_name/ ) {
    print "granting all privileges on $db_name database to $db_user , please insert root password...\n";
    $cmd = "mysql -h $dbip  -P $dbport -u root -p$root_passwd -e \"GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user' WITH GRANT OPTION\"";
    $exec = `$cmd 2>&1`;
    print "done\n";
}else {
    print "User seems to have good privileges\n";
}

#We now generate the database schemas
print "generating database schemas...";
$cmd ="mysql -h $dbip  -P $dbport -u $db_user -p$db_pwd < $conf_vars->{schema_sql}";
$exec = `$cmd 2>&1`;
print "done\n";

#We now generate the components schemas
print "loading component DB schemas...\n";
open (my $FILE, "<","$conf_vars->{comp_conf}");

my $line;
while( defined( $line = <$FILE> ) )
{
    $/ = "\r\n";
    chomp ($line);
    # don't proceed empty lines or commented lines
    next if (( ! $line ) || ( $line =~ /^#/ ));
    print "installing $line component in database from $conf_vars->{comp_schemas_dir}$line.sql...\n ";
    $cmd = "mysql -u $db_user -p$db_pwd < $conf_vars->{comp_schemas_dir}$line.sql";
    $exec = `$cmd 2>&1`;
    print "done\n";
}
close($FILE);
print "components DB schemas loaded\n";

#And to conclude, we insert initial datas in the DB
print "inserting initial datas...";
$cmd = "mysql -u $db_user -p$db_pwd < $conf_vars->{data_sql}"; 
$exec = `$cmd 2>&1`;
print "done\n";

#######################
#Service configuration#
#######################

# Dancer configuration
useTemplate(
    template => "dancer_cfg.tt",
    datas    => {
       log_directory => $log_directory
    },
    conf     => "/opt/kanopya/ui/Frontend/config.yml",
    include  => $conf_vars->{install_template_dir}
);


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
    exit if ( $validate_licence ne 'y' );
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
    foreach my $files (keys %$conf_files){
        foreach my $d (keys %{$conf_files->{$files}->{datas}}){
            $datas{$d} = $conf_data{$d};
        }        
        useTemplate(
            template => $conf_files->{$files}->{template},
            datas    => \%datas,
            conf     => $conf_vars->{conf_dir} . $files,
            include  => $conf_vars->{install_template_dir}
        );
    }
}

sub useTemplate{
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