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
my $debian_version;
my $conf_dir = '/etc/kanopya/';
my $kanopya_dir = '/opt/kanopya/';
my $components_conf = $conf_dir.'components.conf';
my $administrator_conf = $conf_dir.'administrator.conf';
my $executor_conf = $conf_dir.'executor.conf';
my $monitor_conf = $conf_dir.'monitor.conf';
my $executor_log_conf = $conf_dir.'executor-log.conf';
my $monitor_log_conf = $conf_dir.'monitor-log.conf';
my $orchestrator_conf = $conf_dir.'orchestrator.conf';
my $orchestrator_log_conf = $conf_dir.'orchestrator-log.conf';
my $state_manager_log_conf = $conf_dir.'state-manager-log.conf';
my $webui_log_conf = $conf_dir.'webui-log.conf';
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

print "please enter the nameserver that admin will use: ";
$nameserver = <STDIN>;
chomp($nameserver);
while ($nameserver !~ m/^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/)
{
	print "you must enter a valid ipv4 address: ";
	$nameserver = <STDIN>;
	chomp($nameserver);
	my @ip = split /\./, $nameserver;
	for (my $i = 0; $i < @ip; $i++)
	{
		while (!($ip[$i] <= 255))
		{
			last;
		}
	}
	
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
if ($kanopya_logdir !~ m/\/$/){
	$kanopya_logdir = $kanopya_logdir.'/';
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

#We can now create the database credentials
print "creating mysql user...\n";
system ("mysql -h $db_location -P $db_port -u root -p -e \"CREATE USER '$db_user' IDENTIFIED BY '$db_user_pwd'\"") == 0 or die "error while creating mysql user: $!";
print "done\n";

#Then we create the logging directory
print "creating the logging directory...";
system ("mkdir -p $kanopya_logdir") == 0 or die "error while creating the logging directory: $!";
print "done\n";


#We remove an annoying line from /etc/inetd.conf that avoid atftpd to run properly 
system ('sed "/^tftp/d" /etc/inetd.conf > tmp');
system('mv tmp /etc/inetd.conf');
system('invoke-rc.d atftpd restart');

#We configure dhcp server with the gathered informations
#As conf file changes from lenny to squeeze, we need to handle both cases
open (FILE, "</etc/debian_version") or die "error while opening /etc/debian_version: $!";
my $line;
while ($line = <FILE>){
	if ($line =~ m/^6\./ || $line =~ m/^squeeze/){
		print 'version stable: '.$line."\n";
		$debian_version = 'squeeze';
	}elsif ($line =~ m/^5\./ || $line =~ m/^lenny/){
		print 'ancienne stable: '.$line."\n";
		$debian_version = 'lenny';
	}
}
if ($debian_version eq 'squeeze'){
	open (FILE, ">/etc/dhcp/dhcpd.conf") or die "an error occured while opening /etc/dhcp/dhcpd.conf: $!";
	print FILE 'ddns-update-style none;'."\n".'default-lease-time 600;'."\n".'max-lease-time 7200;'."\n".'log-facility local7;'."\n".'subnet '.$mcs_internal_network.' netmask '.$mcs_internal_network_mask.'{'."\n".'	option domain-name-servers '.$nameserver.";\n".'}'."\n";
	system('invoke-rc.d isc-dhcp-server restart');
}elsif ($debian_version eq 'lenny'){
	open (FILE, ">/etc/dhcp3/dhcpd.conf") or die "an error occured while opening /etc/dhcp/dhcpd.conf: $!";
	print FILE 'ddns-update-style none;'."\n".'default-lease-time 600;'."\n".'max-lease-time 7200;'."\n".'log-facility local7;'."\n".'subnet '.$mcs_internal_network.' netmask '.$mcs_internal_network_mask.'{'."\n".'	option domain-name-servers '.$nameserver.";\n".'}'."\n";
	system('invoke-rc.d dhcpd restart');
}else{ 
	print 'we can\'t determine the Debian version you are running, please check /etc/debian_version';
}

#We will now create the configuration files for Kanopya
#Note: components.conf is the only file shipped with packages. Others are generated here.
#We create the administrator.conf file, and place it at the place defined earlier for conf files ($conf_dir)
print "creating administrator.conf...";
system("touch $administrator_conf") == 0 or die "error while touching administrator.conf: $!";
print "done\n";
print "filling administrator.conf...";
open (FILE, ">$administrator_conf") or die "error while opening administrator.conf: $!"; 
print FILE "<config logdir=\"$kanopya_logdir\">\n<internalnetwork ip=\"$mcs_internal_network\" mask=\"$mcs_internal_network_mask\" gateway=\"$mcs_gateway\"/>\n<dbconf type=\"mysql\" name=\"administrator\" user=\"$db_user\" password=\"$db_user_pwd\" port=\"$db_port\" host=\"$db_location\" debug=\"$debug\"/>\n</config>";
close (FILE);
print "done\n";

#We create the executor.conf file
print "creating executor.conf...";
system("touch $executor_conf") == 0 or die "error while touching executor.conf: $!";
print "done\n";
print "filling executor.conf...";
open (FILE, ">$executor_conf") or die "error while opening executor.conf: $!"; 
print FILE "<config logdir=\"$kanopya_logdir\">\n<internalnetwork ip=\"$mcs_internal_network\" mask=\"$mcs_internal_network_mask\" gateway=\"$mcs_gateway\"/>\n<user name=\"executer\" password=\"executer\"/>\n<cluster executor=\"1\" bootserver=\"1\" nas=\"1\" monitor=\"1\"/>\n</config>";
close (FILE);
print "done\n";

#We create the monitor.conf file
print "creating monitor.conf...";
system("touch $monitor_conf") == 0 or die "error while touching monitor.conf: $!";
print "done\n";
print "filling monitor.conf...";
open (FILE, ">$monitor_conf") or die "error while opening monitor.conf: $!"; 
print FILE "<conf graph_dir=\"/tmp/monitor/graph\" period=\"86400\" rrd_base_dir=\"/var/cache/kanopya/monitor/base\" time_step=\"30\">\n<generate_graph time_step='40'/>\n<node_states starting_max_time=\"120\" stopping_max_time=\"60\"/>\n<internalnetwork gateway=\"$mcs_gateway\" ip=\"$mcs_internal_network\" mask=\"$mcs_internal_network_mask\"/>\n<user name=\"admin\" password=\"admin\"/>\n</conf>";
close (FILE);
print "done\n";

#We create the orchestrator.conf file
print "creating orchestrator.conf...";
system("touch $orchestrator_conf") == 0 or die "error while touching orchestrator.conf: $!";
print "done\n";
print "filling orchestrator.conf...";
open (FILE, ">$orchestrator_conf") or die "error while opening orchestrator.conf: $!"; 
print FILE "<config time_step='20' rrd_base_dir='/var/cache/mcs/orchestrator/base' graph_dir='/tmp/orchestrator/graph'>\n<user name=\"admin\" password=\"admin\"/>\n</config>";
close (FILE);
print "done\n";

#We now create the executor-log.conf file
print "creating executor-log.conf...";
system("touch $executor_log_conf") == 0 or die "error while touching executor-log.conf: $!";
print "done\n";
print "filling executor-log.conf...";
open (FILE, ">$executor_log_conf") or die "error while opening executor-log.conf: $!"; 
print FILE "log4perl.logger.executor=DEBUG, A1\nlog4perl.appender.A1=Log::Dispatch::File\nlog4perl.appender.A1.filename=".$kanopya_logdir."executor.log\nlog4perl.appender.A1.mode=append\nlog4perl.appender.A1.layout=Log::Log4perl::Layout::PatternLayout\nlog4perl.appender.A1.layout.ConversionPattern=%d %p> %F{1}:%L %M - %m%n\nlog4perl.logger.administrator=DEBUG, A2\nlog4perl.appender.A2=Log::Dispatch::File\nlog4perl.appender.A2.filename=".$kanopya_logdir."executor-administrator.log\nlog4perl.appender.A2.mode=append\nlog4perl.appender.A2.layout=Log::Log4perl::Layout::PatternLayout\nlog4perl.appender.A2.layout.ConversionPattern=%d %p> %F{1}:%L %M - %m%n";
close (FILE);
print "done\n";

#We now create the monitor-log.conf file
print "creating monitor-log.conf...";
system("touch $monitor_log_conf") == 0 or die "error while touching monitor-log.conf: $!";
print "done\n";
print "filling monitor-log.conf...";
open (FILE, ">$monitor_log_conf") or die "error while opening monitor-log.conf: $!"; 
print FILE "log4perl.logger.administrator=DEBUG, A1\nlog4perl.appender.A1=Log::Dispatch::File\nlog4perl.appender.A1.filename=".$kanopya_logdir."monitor-administrator.log\nlog4perl.appender.A1.mode=append\nlog4perl.appender.A1.layout=Log::Log4perl::Layout::PatternLayout\nlog4perl.appender.A1.layout.ConversionPattern=%d %p> %F{1}:%L %M - %m%n\n\nlog4perl.logger.monitor=DEBUG, A2\nlog4perl.appender.A2=Log::Dispatch::File\nlog4perl.appender.A2.filename=".$kanopya_logdir."monitor.log\nlog4perl.appender.A2.mode=append\nlog4perl.appender.A2.layout=Log::Log4perl::Layout::PatternLayout\nlog4perl.appender.A2.layout.ConversionPattern=%d %p> %F{1}:%L %M - %m%n\n\nlog4perl.logger.collector=DEBUG, A3\nlog4perl.appender.A3=Log::Dispatch::File\nlog4perl.appender.A3.filename=".$kanopya_logdir."collector.log\nlog4perl.appender.A3.mode=append\nlog4perl.appender.A3.layout=Log::Log4perl::Layout::PatternLayout\nlog4perl.appender.A3.layout.ConversionPattern=%d %p> %M - %m%n\n\nlog4perl.logger.grapher=DEBUG, A4\nlog4perl.appender.A4=Log::Dispatch::File\nlog4perl.appender.A4.filename=".$kanopya_logdir."grapher.log\nlog4perl.appender.A4.mode=append\nlog4perl.appender.A4.layout=Log::Log4perl::Layout::PatternLayout\nlog4perl.appender.A4.layout.ConversionPattern=%d %p> %F{1}:%L %M - %m%n\n";
close (FILE);
print "done\n";


#We now create the orchestrator-log.conf file
print "creating orchestrator-log.conf...";
system("touch $orchestrator_log_conf") == 0 or die "error while touching orchestrator-log.conf: $!";
print "done\n";
print "filling orchestrator-log.conf...";
open (FILE, ">$orchestrator_log_conf") or die "error while opening orchestrator-log.conf: $!"; 
print FILE "log4perl.logger.orchestrator=DEBUG, A1\nlog4perl.appender.A1=Log::Dispatch::File\nlog4perl.appender.A1.filename=".$kanopya_logdir."orchestrator.log\nlog4perl.appender.A1.mode=append\nlog4perl.appender.A1.layout=Log::Log4perl::Layout::PatternLayout\nlog4perl.appender.A1.layout.ConversionPattern=%d %p> %F{1}:%L %M - %m%n\n\nlog4perl.logger.administrator=DEBUG, A2\nlog4perl.appender.A2=Log::Dispatch::File\nlog4perl.appender.A2.filename=".$kanopya_logdir."orchestrator-administrator.log\nlog4perl.appender.A2.mode=append\nlog4perl.appender.A2.layout=Log::Log4perl::Layout::PatternLayout\nlog4perl.appender.A2.layout.ConversionPattern=%d %p> %F{1}:%L %M - %m%n";
close (FILE);
print "done\n";

#We now create the state-manager-log.conf file
print "creating state-manager-log.conf...";
system("touch $state_manager_log_conf") == 0 or die "error while touching state-manager-log.conf: $!";
print "done\n";
print "filling state-manager-log.conf...";
open (FILE, ">$state_manager_log_conf") or die "error while opening state-manager-log.conf: $!"; 
print FILE "log4perl.logger.administrator=DEBUG, A1\nlog4perl.appender.A1=Log::Dispatch::File\nlog4perl.appender.A1.filename=".$kanopya_logdir."state-manager-administrator.log\nlog4perl.appender.A1.mode=append\nlog4perl.appender.A1.layout=Log::Log4perl::Layout::PatternLayout\nlog4perl.appender.A1.layout.ConversionPattern=%d %p> %F{1}:%L %M - %m%n\n\nlog4perl.logger.statemanager=DEBUG, A2\nlog4perl.appender.A2=Log::Dispatch::File\nlog4perl.appender.A2.filename=".$kanopya_logdir."state-manager.log\nlog4perl.appender.A2.mode=append\nlog4perl.appender.A2.layout=Log::Log4perl::Layout::PatternLayout\nlog4perl.appender.A2.layout.ConversionPattern=%d %p> %F{1}:%L %M - %m%n\n";
close (FILE);
print "done\n";

#We now create the webui-log.conf file
print "creating webui-log.conf...";
system("touch $webui_log_conf") == 0 or die "error while touching webui-log.conf: $!";
print "done\n";
print "filling webui-log.conf...";
open (FILE, ">$webui_log_conf") or die "error while opening webui-log.conf: $!"; 
print FILE "log4perl.logger.webui=DEBUG, A1\nlog4perl.appender.A1=Log::Dispatch::File\nlog4perl.appender.A1.filename=".$kanopya_logdir."webui.log\nlog4perl.appender.A1.mode=append\nlog4perl.appender.A1.layout=Log::Log4perl::Layout::PatternLayout\nlog4perl.appender.A1.layout.ConversionPattern=%d %p> %M - %m%n\n\nlog4perl.logger.administrator=DEBUG, A2\nlog4perl.appender.A2=Log::Dispatch::File\nlog4perl.appender.A2.filename=".$kanopya_logdir."webui-administrator.log\nlog4perl.appender.A2.mode=append\nlog4perl.appender.A2.layout=Log::Log4perl::Layout::PatternLayout\nlog4perl.appender.A2.layout.ConversionPattern=%d %p> %F{1}:%L %M - %m%n\n";
close (FILE);
print "done\n";
#TEMPORARY we put webui-log.conf file in the /opt/kanopya/conf/ dir (cf ui/web/cgi/kanopya.cgi)
system ('mkdir /opt/kanopya/conf') == 0 or die "$!";
system ('cp /etc/kanopya/webui-log.conf /opt/kanopya/conf/') == 0 or die "$!"; 

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
print "launching kanopya's init script...\n";
# We now launch the init scripts.
system('/etc/init.d/kanopya-executor restart');
system('/etc/init.d/kanopya-orchestrator restart');
system('/etc/init.d/kanopya-grapher restart');
system('/etc/init.d/kanopya-collector restart');
print "\nYou can now visit http://localhost/cgi/kanopya.cgi and start using Kanopya!\n";
