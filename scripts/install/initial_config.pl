#!/usr/bin/perl -W

#This scripts has to be executed as root or with sudo, after Kanopya's installation through a package manager.
#it's goal is to generate administrator.conf, to create kanopya system user and then to populate the database.
#@Author: Maxime Demoulin <maxime.demoulin@hederatech.com>
#@Date: 23/02/2011

use strict;
use Term::ReadKey;
use Template;

#we first prompt the user for the required informations, that will be used to generate administrator.conf
my $db_user;
print "please enter the database's user: ";
$db_user = <STDIN>;
chomp($db_user);

my $db_user_pwd;
ReadMode('noecho');
print "please enter the user's password: ";
$db_user_pwd = <STDIN>;
chomp($db_user_pwd);
ReadMode ("original");

my $db_location;
print "\nplease enter the database's url or domain name: ";
$db_location = <STDIN>;
chomp($db_location);

my $db_port;
print "please enter the database's port: ";
$db_port = <STDIN>;
chomp($db_port);

my $mcs_internal_network;
print "please enter the Kanopya's internal network address: ";
$mcs_internal_network = <STDIN>;
chomp($mcs_internal_network);

my $mcs_gateway;
print "please enter the gateway for kanopya's network: ";
$mcs_gateway = <STDIN>;
chomp($mcs_gateway);

my $mcs_internal_network_netmask;
print "please enter the internal network netmask: ";
$mcs_internal_network_netmask = <STDIN>;
chomp($mcs_internal_network_netmask);

my $kanopya_logdir;
print "please enter the emplacement of kanopya's logging directory: ";
$kanopya_logdir = <STDIN>;
chomp($kanopya_logdir);

my $kanopya_pv;
print "please enter the physical volumes name, separated by a comma: ";
$kanopya_pv = <STDIN>;
chomp($kanopya_pv);
my @kanopya_pvs = split(",", $kanopya_pv);

my $kanopya_vg_name;
print "please name the volume group used by admin: ";
$kanopya_vg_name = <STDIN>;
chomp($kanopya_vg_name);

my $kanopya_vg_total_size;
print "please enter the volume group's total size: ";
$kanopya_vg_total_size = <STDIN>;
chomp($kanopya_vg_total_size);

my $kanopya_vg_free_space;
print "please enter the volume group's free size: ";
$kanopya_vg_free_space = <STDIN>;
chomp($kanopya_vg_free_space);

#We can now create the database credentials
print "creating mysql user...";
system ("mysql -h localhost -u root -p -e \"CREATE USER '$db_user' IDENTIFIED BY '$db_user_pwd'\"");
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

#TEMPORARY: we make www-data owner of /opt/kanopya/logs
system ("chown -R www-data.www-data /opt/kanopya/logs");

#Then we create the logging directory
print "creating the logging directory...";
system ("mkdir $kanopya_logdir");
print "done\n";

#We then create the administrator.conf file, and place it under /etc/kanopya/administrator.conf
print "creating administrator.conf...";
my $administrator_conf = "/etc/kanopya/administrator.conf";
system("touch $administrator_conf");
print "done\n";
print "filling administrator.conf...";
open (FILE, ">$administrator_conf") or die "open: $!"; 
print FILE "<config logdir=\"$kanopya_logdir\">\n<internalnetwork ip=\"$mcs_internal_network\" mask=\"$mcs_internal_network_netmask\" gateway=\"$mcs_gateway\"/>\n<dbconf type=\"mysql\" name=\"administrator\" user=\"$db_user\" password=\"$db_user_pwd\" port=\"$db_port\" host=\"$db_location\" debug=\"0\"/>\n</config>";
close (FILE);
print "done\n";

#We will now generate the Data.sql file, and populate the database, and finally we give privileges to the db_user
print "generating Data.sql...";
my $template_dir="/opt/kanopya/scripts/database/mysql/data/";
my $config = {
	INCLUDE_PATH => $template_dir,
	INTERPOLATE  => 1,
	POST_CHOMP   => 1,
	EVAL_PERL    => 1,
};
my $template = Template->new($config);
my $input = "Data.sql.tt";
my %datas = (kanopya_vg_name => $kanopya_vg_name, kanopya_vg_total_size => $kanopya_vg_total_size, kanopya_vg_free_space => $kanopya_vg_free_space, kanopya_pvs => \@kanopya_pvs);
$template->process($input, \%datas, $template_dir."Data.sql") || do {
	print "error while generating Data.sql: $!";
};
print "done\n";
print "granting all privileges on administrator database to $db_user... ";
system ("mysql -h localhost -u root -p -e \"GRANT ALL PRIVILEGES ON administrator.* TO '$db_user' WITH GRANT OPTION\"");
print "done\n";
print "populating the database...";
my $resetdb = "/opt/kanopya/scripts/database/mysql/sbin/resetdb.sh";
system("sh $resetdb");
print "done\n";
