#!/usr/bin/perl -W

#This scripts has to be executed as root or with sudo, after Kanopya's installation through a package manager.
#it's goal is to generate administrator.conf, to create kanopya system user and then to populate the database.
#@Author: Maxime Demoulin <maxime.demoulin@hederatech.com>
#@Date: 23/02/2011

use strict;
use Term::ReadKey;
use Template;
use NetAddr::IP;

##############################
##VARIABLES DECLARATION ZONE##
##############################
#variables that handles the user's answers
my $db_user;
my $db_user_pwd;
my $db_location;
my $db_port;
my $mcs_internal_network;
my $mcs_admin_internal_ip;
my $mcs_gateway;
my $mcs_internal_network_mask;
my $kanopya_logdir;
my $kanopya_pv;
my $kanopya_vg_name;
my $kanopya_vg_total_size;
my $kanopya_vg_free_space;
my $admin_user_pwd;
my $nameserver;
my $mcs_public_network;
my $mcs_admin_public_ip;
my $mcs_public_network_mask;
#this variable will handle the rollback operation in case of script failure
my @rollback;

#debug mode for administrator.conf

my $debug = 0;

#variables that handles locations used through this script
my $conf_dir = '/etc/kanopya/';
my $kanopya_dir = '/opt/kanopya/';
my $components_conf = $conf_dir.'components.conf';
my $administrator_conf = $conf_dir.'administrator.conf';
my $mysql_dir =  $kanopya_dir.'scripts/database/mysql/';
my $schemas_dir = $mysql_dir.'schemas/';
my $data_dir = $mysql_dir.'data/';
my $schema_sql = $schemas_dir.'Schemas.sql';
my $data_sql = $schemas_dir.'Data.sql';
my $components_sql_dir = $schemas_dir.'components/';
#############################
#############################
#############################

#we first prompt the user for the required informations, that will be used to generate administrator.conf
print 'please enter the database\'s user: ';
$db_user = <STDIN>;
chomp($db_user);
while (length($db_user)==0){
	print "you can't give a null database's user name, please enter a database's user: ";
	$db_user = <STDIN>;
	chomp($db_user);
}

ReadMode('noecho');
print "please enter the user's password: ";
$db_user_pwd = <STDIN>;
chomp($db_user_pwd);
while (length($db_user_pwd)==0){
	print "you can't give a null password to your database's user, please enter a password: ";
	$db_user_pwd = <STDIN>;
	chomp($db_user_pwd);
}
ReadMode ("original");

print "\nplease enter the database's url or domain name: ";
$db_location = <STDIN>;
chomp($db_location);
while (length($db_location)==0){
	print "you can't give a null location for the database: ";
	$db_location = <STDIN>;
	chomp($db_location);
}

print "please enter the database's port (it should be 3306 by default): ";
$db_port = <STDIN>;
chomp($db_port);
while ($db_port =~ m/\D/  || length($db_port) == 0 || $db_port == 0 || $db_port >= 65535 ){
	print "you must enter a valid port number, within 1 and 65535: ";
	$db_port = <STDIN>;
	chomp($db_port);
}

print "please enter the Kanopya's internal network address: ";
$mcs_internal_network = <STDIN>;
chomp($mcs_internal_network);
while ($mcs_internal_network !~ m/^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/)
{
	print "you must enter a valid ipv4 address: ";	
	$mcs_internal_network = <STDIN>;
	chomp($mcs_internal_network);
	my @ip = split /\./, $mcs_internal_network;
	for (my $i = 0; $i < @ip; $i++)
	{
		while (!($ip[$i] <= 255))
		{
			last;
		}
	}
}

print "please enter the gateway for kanopya's network: ";
$mcs_gateway = <STDIN>;
chomp($mcs_gateway);
while ($mcs_gateway !~ m/^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/)
{
	print "you must enter a valid ipv4 address: ";	
	$mcs_gateway = <STDIN>;
	chomp($mcs_gateway);
	my @ip = split /\./, $mcs_gateway;
	for (my $i = 0; $i < @ip; $i++)
	{
		while (!($ip[$i] <= 255))
		{
			last;
		}
	}
}

print "please enter the internal network netmask: ";
$mcs_internal_network_mask = <STDIN>;
chomp($mcs_internal_network_mask);
while ($mcs_internal_network_mask !~ m/^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/)
{
	print "you must enter a valid ipv4 address: ";	
	$mcs_internal_network_mask = <STDIN>;
	chomp($mcs_internal_network_mask);
	my @ip = split /\./, $mcs_internal_network_mask;
	for (my $i = 0; $i < @ip; $i++)
	{
		while (!($ip[$i] <= 255))
		{
			last;
		}
	}
}

print "calculating the first host address available for this network...";
my $network_addr = NetAddr::IP->new($mcs_internal_network, $mcs_internal_network_mask);
my @c = split("/",$network_addr->first);
$mcs_admin_internal_ip = $c[0];
print "done (address set to $mcs_admin_internal_ip)\n";

print "please enter the public network address: ";
$mcs_public_network = <STDIN>;
chomp($mcs_public_network);
while ($mcs_public_network !~ m/^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/)
{
	print "you must enter a valid ipv4 address: ";	
	$mcs_public_network = <STDIN>;
	chomp($mcs_public_network);
	my @ip = split /\./, $mcs_public_network;
	for (my $i = 0; $i < @ip; $i++)
	{
		while (!($ip[$i] <= 255))
		{
			last;
		}
	}
}

print "please enter the public network mask address: ";
$mcs_public_network_mask = <STDIN>;
chomp($mcs_public_network_mask);
while ($mcs_public_network_mask !~ m/^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/)
{
        print "you must enter a valid ipv4 address: ";
        $mcs_public_network_mask = <STDIN>;
        chomp($mcs_public_network_mask);
        my @ip = split /\./, $mcs_public_network;
        for (my $i = 0; $i < @ip; $i++)
        {
                while (!($ip[$i] <= 255))
                {
                        last;
                }
        }
}

print "please enter the admin public ip address: ";
$mcs_admin_public_ip = <STDIN>;
chomp($mcs_admin_public_ip);
while ($mcs_admin_public_ip !~ m/^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/)
{
        print "you must enter a valid ipv4 address: ";
        $mcs_admin_public_ip = <STDIN>;
        chomp($mcs_admin_public_ip);
        my @ip = split /\./, $mcs_admin_public_ip;
        for (my $i = 0; $i < @ip; $i++)
        {
                while (!($ip[$i] <= 255))
                {
                        last;
                }
        }
}


print "please enter the absolute path of kanopya's logging directory: ";
$kanopya_logdir = <STDIN>;
chomp($kanopya_logdir);
while ($kanopya_logdir !~ m/^\//){
	print "'".$kanopya_logdir."' is not an absolute path. Absolute path starts with the '/' symbol that represents the root of the filesystem: ";
	$kanopya_logdir = <STDIN>;
	chomp($kanopya_logdir);
}

print "please enter the physical volumes name, separated by a comma: ";
$kanopya_pv = <STDIN>;
chomp($kanopya_pv);
while (length($kanopya_pv)==0 || $kanopya_pv !~ m/^\//){
	print "you must enter at least one physical volume name. It must contain the absolute path to the volume. Absolute path starts with the '/' symbol, that represents the root of the filesystem: ";
	$kanopya_pv = <STDIN>;
	chomp($kanopya_pv);
}
my @kanopya_pvs = split(",", $kanopya_pv);

print "please name the volume group used by admin: ";
$kanopya_vg_name = <STDIN>;
chomp($kanopya_vg_name);
while (length($kanopya_vg_name)==0){
	print "you must enter a volume group name: ";
	$kanopya_vg_name = <STDIN>;
	chomp($kanopya_vg_name);
}

print "please enter the volume group's total size in Mo: ";
$kanopya_vg_total_size = <STDIN>;
chomp($kanopya_vg_total_size);
while ($kanopya_vg_total_size =~ m/\D/ || $kanopya_vg_total_size == 0){
	print "please enter a valid size for your volume group (digit non equal to 0): ";
	$kanopya_vg_total_size = <STDIN>;
	chomp($kanopya_vg_total_size);
}

print "please enter the volume group's free space in Mo: ";
$kanopya_vg_free_space = <STDIN>;
chomp($kanopya_vg_free_space);
while ($kanopya_vg_free_space =~ m/\D/ || $kanopya_vg_free_space == 0){
	print "please enter a valid free space value for your volume group (digit non equal to 0): ";
	$kanopya_vg_free_space = <STDIN>;
	chomp($kanopya_vg_free_space);
}

##ToDo: prompt the user for a custom admin user password
# print "please enter the kanopya's admin user password: ";
# $admin_user_pwd = <STDIN>;
# chomp($admin_user_pwd);

#We can now create the database credentials
print "creating mysql user...\n";
system ("mysql -h $db_location -P $db_port -u root -p -e \"CREATE USER '$db_user' IDENTIFIED BY '$db_user_pwd'\"") == 0 or die "error while creating mysql user: $!";
print "done\n";

#We create Kanopya system user
#if (!defined(getpwnam("kanopya")))
#{
#	print "adding user kanopya to the system\n";	
#	system("useradd kanopya");
#	print "please set kanopya's password: \n";
#	system("passwd kanopya");
#}

#We then make him owner of kanopya's files and directories
#if (defined(getpwnam("kanopya")))
#{
#	print "making kanopya owner of ...";
#	system ("chown -R kanopya.kanopya /opt/kanopya");
#}

#Then we create the logging directory
print "creating the logging directory...";
system ("mkdir -p $kanopya_logdir") == 0 or die "error while creating the logging directory: $!";
print "done\n";

#We modify /etc/default/atftpd to make it fit to the tftp component configuration (we turn use of inetd to false and give /tftp instead of /srv/tftp as dir
my $atftpd_default='/etc/default/atftpd';
open (FILE, ">$atftpd_default") or die ("couldn't open file: $!");
print FILE "USE_INETD=false\nOPTIONS=\"--tftpd-timeout 300 --retry-timeout 5 --mcast-port 1758 --mcast-addr 239.239.239.0-255 --mcast-ttl 1 --maxthread 100 --verbose=5 /tftp\"";
close (FILE);

#TEMPORARY: we make www-data owner of /opt/kanopya/logs after having created it
system ("mkdir /opt/kanopya/logs") == 0 or die "$!";
system ("chown -R www-data.www-data /opt/kanopya/logs") == 0 or die "$!";
#TEMPORARY: we put components.conf in /etc/kanopya
system ("cp /etc/kanopya/samples/components.conf /etc/kanopya") == 0 or die "$!";

#We then create the administrator.conf file, and place it under /etc/kanopya/administrator.conf
print "creating administrator.conf...";
system("touch $administrator_conf") == 0 or die "error while touching administrator.conf: $!";
print "done\n";
print "filling administrator.conf...";
open (FILE, ">$administrator_conf") or die "error while opening administrator.conf: $!"; 
print FILE "<config logdir=\"$kanopya_logdir\">\n<internalnetwork ip=\"$mcs_internal_network\" mask=\"$mcs_internal_network_mask\" gateway=\"$mcs_gateway\"/>\n<dbconf type=\"mysql\" name=\"administrator\" user=\"$db_user\" password=\"$db_user_pwd\" port=\"$db_port\" host=\"$db_location\" debug=\"$debug\"/>\n</config>";
close (FILE);
print "done\n";

#We will now generate the Data.sql file
print "generating user_data.sql...";
my $config = {
	INCLUDE_PATH => $data_dir,
	INTERPOLATE  => 1,
	POST_CHOMP   => 1,
	EVAL_PERL    => 1,
};
my $template = Template->new($config);
my $input = "Data.sql.tt";
my %datas = (kanopya_vg_name => $kanopya_vg_name, kanopya_vg_total_size => $kanopya_vg_total_size, kanopya_vg_free_space => $kanopya_vg_free_space, kanopya_pvs => \@kanopya_pvs, ipv4_internal_ip => $mcs_admin_internal_ip, ipv4_internal_netmask => $mcs_internal_network_mask, ipv4_internal_network_ip => $mcs_internal_network, nameserver => $nameserver, ipv4_public_ip => $mcs_admin_public_ip , ipv4_public_netmask => $mcs_public_network_mask );
$template->process($input, \%datas, $data_sql) || do {
	print "error while generating Data.sql: $!";
};
print "done\n";

#We grant all privileges to administrator database for $db_user
print "granting all privileges on administrator database to $db_user...\n";
system ("mysql -h $db_location -P $db_port -u root -p -e \"GRANT ALL PRIVILEGES ON administrator.* TO '$db_user' WITH GRANT OPTION\"") == 0 or die "error while granting privileges to $db_user: $!";
print "done\n";

#We now generate the database schemas
print "generating database schemas...";
system ("mysql -u $db_user -p$db_user_pwd < $schema_sql") == 0 or die "error while generating database schema: $!";
print "done\n";

#We now generate the components schemas 
print "loading component DB schemas...";
open (FILE, "<$components_conf") or die "error while opening components.conf: $!";
my $line;
LINE:
while( defined( $line = <FILE> ) )
{
	chomp ($line);
	print "installing $line component in database from $components_sql_dir$line.sql...\n ";
	system("mysql -u $db_user -p$db_user_pwd < $components_sql_dir$line.sql");
	print "done\n";
}
close(FILE);
print "components DB schemas loaded\n";

#And to conclude, we insert initial, datas in the DB
print "inserting initial datas...";
system ("mysql -u $db_user -p$db_user_pwd < $data_sql") == 0 or die "error while inserting initial datas: $!";
print "done\n";
print "initial configuration: done.\n";
