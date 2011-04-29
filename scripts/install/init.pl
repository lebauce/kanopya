#!/usr/bin/perl -W
# init.pl -  

# Copyright (C) 2009, 2010, 2011, 2012, 2013
#   Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to the
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 14 july 2010
#This scripts has to be executed as root or with sudo, after Kanopya's installation through a package manager.
#it's goal is to generate administrator.conf, to create kanopya system user and then to populate the database.
#@Date: 23/02/2011

use strict;
use Term::ReadKey;
use Template;
use NetAddr::IP;
use XML::Simple;
use Data::Dumper;

#Scripts variables, used to set stuff like path, users, etc
my $kanopya_dir = '/opt/kanopya/';
my $conf_dir = '/etc/kanopya/';
my $components_conf = $conf_dir.'components.conf';
my $mysql_dir =  $kanopya_dir.'scripts/database/mysql/';
my $schemas_dir = $mysql_dir.'schemas/';
my $data_dir = $mysql_dir.'data/';
my $schema_sql = $schemas_dir.'Schemas.sql';
my $data_sql = $data_dir.'Data.sql';
my $components_dir = $schemas_dir.'components/';
my $apache_user = 'www-data';

my $install_conf = XMLin("init_struct.xml");
my $questions = $install_conf->{questions};
my $answers ={};

my %param_test = (dbuser => \&matchRegexp,
                  dbpassword1 => sub {},
                  dbpassword2 => \&comparePassword,
                  dbip => \&checkIpOrHostname,
                  dbport => \&checkPort,
                  kanopya_server_domain_name=> \&matchRegexp,
                  internal_net_interface => \&matchRegexp,
                  internal_net_add => \&checkIp,
                  internal_net_mask => \&checkIp,
                  log_directory => \&matchRegexp);

printInitStruct();
#Welcome message - accepting Licence is mandatory
welcome();
#Ask questions to users 
getConf();
#Print user's answers, can be usefull for recap, etc
#printAnswers();
#Functions used to generate conf files - may them be called from within another mother function?
genConf();




sub genConf(){
    genLibkanopyaConf();
    genCoreConf();
    genMonitorConf();
    genOrchestratorConf();
    genStateManagerConf();
    genWebuiConf();

#Network setup
print "calculating the first host address available for this network...";
my $internal_ip_add = NetAddr::IP->new($answers->{internal_net_add}, $answers->{internal_net_mask});
my @c = split("/",$internal_ip_add->first);
$internal_ip_add = $c[0];
print "done (first host address is $internal_ip_add)\n";
print "setting up $answers->{internal_net_interface} ...";
system ("ifconfig $answers->{internal_net_interface} $internal_ip_add") == 0 or die "an error occured while trying to set up nic ($answers->{internal_net_interface}) address: $!";
print "done\n";
#We gather the NIC's MAC address
my $internal_net_interface_mac_add = `ip link list dev $answers->{internal_net_interface} | egrep "ether [0-9a-zA-Z]{2}:[0-9a-zA-Z]{2}:[0-9a-zA-Z]{2}:[0-9a-zA-Z]{2}:[0-9a-zA-Z]{2}:[0-9a-zA-Z]{2}" | cut -d' ' -f6`;

#Directory manipulations
#Then we create the logging directory and give rights to apache on it
print "creating the logging directory...";
system ("mkdir -p $answers->{log_directory}") == 0 or die "error while creating the logging directory: $!";
system ("chown -R $apache_user.$apache_user $answers->{log_directory}") == 0 or die "error while granting rights on $answers->{log_directory} to $apache_user: $!";
print "done\n";
#TEMPORARY we put webui-log.conf file in the /opt/kanopya/conf/ dir (cf ui/web/cgi/kanopya.cgi)
system ('mkdir /opt/kanopya/conf') == 0 or die "$!";
system ('cp /etc/kanopya/webui-log.conf /opt/kanopya/conf/') == 0 or die "$!";

#We configure dhcp server with the gathered informations
#As conf file changes from lenny to squeeze, we need to handle both cases
open (FILE, "</etc/debian_version") or die "error while opening /etc/debian_version: $!";
my $line;
my $debian_version;
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
        print FILE 'ddns-update-style none;'."\n".'default-lease-time 600;'."\n".'max-lease-time 7200;'."\n".'log-facility local7;'."\n".'subnet '.$answers->{internal_net_add}.' netmask '.$answers->{internal_net_mask}.'{}'."\n";
        system('invoke-rc.d isc-dhcp-server restart');
}elsif ($debian_version eq 'lenny'){
        open (FILE, ">/etc/dhcp3/dhcpd.conf") or die "an error occured while opening /etc/dhcp/dhcpd.conf: $!";
        print FILE 'ddns-update-style none;'."\n".'default-lease-time 600;'."\n".'max-lease-time 7200;'."\n".'log-facility local7;'."\n".'subnet '.$answers->{internal_net_add}.' netmask '.$answers->{internal_net_mask}.'{}'."\n";
        system('invoke-rc.d dhcpd restart');
}else{
        print 'we can\'t determine the Debian version you are running, please check /etc/debian_version';
}
close (FILE);
#Atftpd configuration
open (FILE, ">/etc/default/atftpd") or die "an error occured while opening /etc/default/atftpd: $!";
print FILE "USE_INETD=false\nOPTIONS=\"--daemon --tftpd-timeout 300 --retry-timeout 5 --no-multicast --bind-address $internal_ip_add --maxthread 100 --verbose=5 --logfile=/var/log/tftp.log /tftp\"";
close (FILE);


#We generate the Data.sql file and setup database
## A L ATTENTION D ANTOINE: CETTE PARTIE EST DONC ENCORE A PORTER (je n'ai mis que le has contenant les données
## IL MANQUE LES DONNEES A CALCULER (VGS) ET LA GENERATION DU FICHIER DATA.SQL, AINSI QUE LES DONNEES CONCERNANT LE RESEAU "PUBLIC"
my %datas = (kanopya_vg_name => $kanopya_vg_name, kanopya_vg_total_size => $kanopya_vg_total_size, kanopya_vg_free_space => $kanopya_vg_free_space, kanopya_pvs => \@kanopya_pvs, ipv4_internal_ip => $internal_ip_add, ipv4_internal_netmask => $answers->{internal_net_mask}, ipv4_internal_network_ip => $answers->{internal_net_add}, nameserver => $nameserver, ipv4_public_ip => $mcs_admin_public_ip , ipv4_public_netmask => $mcs_public_network_mask, admin_domainname => $answers->{kanopya_server_domain_name}, mb_hw_address => $internal_net_interface_mac_add);
        

#Creation of database user
print "creating mysql user...\n";
system ("mysql -h $answers->{dbip}  -P $answers->{dbport} -u root -p -e \"CREATE USER '$answers->{dbuser}' IDENTIFIED BY '$answers->{dbpassword1}'\"") == 0 or die "error while creating mysql user: $!";
print "done\n";

#We grant all privileges to administrator database for $db_user
print "granting all privileges on administrator database to $db_user...\n";
system ("mysql -h $answers->{dbip} -P $answers->{dbport} -u root -p -e \"GRANT ALL PRIVILEGES ON administrator.* TO '$answers->{dbuser}' WITH GRANT OPTION\"") == 0 or die "error while granting privileges to $answers->{dbuser}: $!";
print "done\n";

my 
#We now generate the database schemas
print "generating database schemas...";
system ("mysql -u $answers->{dbuser} -p$answers->{dbpassword1} < $schema_sql") == 0 or die "error while generating database schema: $!";
print "done\n";

#We now generate the components schemas 
print "loading component DB schemas...";
open (FILE, "<$components_conf") or die "error while opening components.conf: $!";
LINE:
while( defined( $line = <FILE> ) )
{
        chomp ($line);
        print "installing $line component in database from $components_dir$line.sql...\n ";
        system("mysql -u $answers->{dbuser} -p$answers->{dbpassword} < $components_dir$line.sql");
        print "done\n";
}
close(FILE);
print "components DB schemas loaded\n";

#And to conclude, we insert initial datas in the DB
print "inserting initial datas...";
system ("mysql -u $answers->{dbuser} -p$answers->{dbpassword} < $data_sql") == 0 or die "error while inserting initial datas: $!";
print "done\n";
print "initial configuration: done.\n";


#Services manipulation
# We stop inetd as it will avoid atftpd to work properly
system('invoke-rc.d inetutils-inetd stop');
# We restart atftpd with the new configuration
system('invoke-rc.d atftpd restart');
# Launching Kanopya's init scripts
system('/etc/init.d/kanopya-executor start');
system('/etc/init.d/kanopya-orchestrator start');
system('/etc/init.d/kanopya-grapher start');
system('/etc/init.d/kanopya-collector start');
print "\nYou can now visit http://localhost/cgi/kanopya.cgi and start using Kanopya!\n";
}

sub welcome {
    my $validate_licence;

    print "Welcome on Kanopya\n";
    print "This script will configure your Kanopya instance\n";
    print "We advise to install Kanopya instance on a dedicated server\n";
    print "First please validate the user licence";
    `cat Licence`;
    print "Do you accept the licence ? (y/n)\n";
    chomp($validate_licence= <STDIN>);
    if ($validate_licence ne 'y'){
        exit;
    }
    print "Please answer to the following questions\n";
}
sub getConf{
    my $i = 0;
    foreach my $question (sort keys %$questions){
        print "question $i : ". $questions->{$question}->{question} . " (". $questions->{$question}->{default} .")\n";
        
        # Secret activation
        if(defined $questions->{$question}->{'is_secret'}){
            ReadMode('noecho');
        }
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

        if (!$answers->{$question}){
            if ($questions->{$question}->{is_searchable} eq "1"){
                print "Script will discover your configuration\n";
                $answers->{$question} = `$questions->{$question}->{search_command}`;
            } else {
                print "Use default value\n";
                $answers->{$question} = $questions->{$question}->{default};
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
            if ($answers->{$question} > scalar @searchable_answer){
                print "Error you entered a value out of the answer scope.";
                default_error();}
            else {
                # On transforme la valeur de l'utilisateur par celle de la selection proposee
                $answers->{$question} = $searchable_answer[$answers->{$question}];
            }
        }
        # Secret deactivation
        if(defined $questions->{$question}->{'is_secret'}){
            ReadMode('original');
        }
        $i++;
        print "\n";
    }
}


sub matchRegexp{
    my %args = @_;
    if ((!defined $args{question} or !exists $args{question})){
        print "Error, did you modify init script ?\n";
        exit;
    }
    if (!defined $questions->{$args{question}}->{pattern}){
        default_error();
    }
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
        exit;
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
    else{
        return checkIp(%args);
    }
    return 0;
}

sub checkIp{
    my %args = @_;
    if ((!defined $args{question} or !exists $args{question})){
        default_error();
    }
	my $ip = new NetAddr::IP($answers->{$args{question}});
	if(not defined $ip) {
	    print "IP <".$answers->{$args{question}}."> seems to be not good";
	    return 1;
	}
	return 0;
}

# Check that password is confirmed
sub comparePassword{
    my %args = @_;
    if ((!defined $args{question} or !exists $args{question})){
        default_error();
    }
    if ($answers->{$args{question}} ne $answers->{'dbpassword1'}){
        print "Password <".$answers->{$args{question}}."> and <".$answers->{'dbpassword1'}."> are differents\n";
        return 1;
    }
    return 0;
}

# When no check method are defined in param_test structure.
sub noMethodToTest {
    print "Error, param get not found in test table.\n";
    print "If you modified your init script or its xml, you may have broken your install";
    exit;
}

# Print xml struct
sub printInitStruct{
    my $i = 0;
    foreach my $question (keys %$questions){
        print "question $i : ". $questions->{$question}->{question} ."\n";
        print "default value : ". $questions->{$question}->{default} ."\n";
        print "question is_searchable : ". $questions->{$question}->{is_searchable} ."\n";
        print "command to search default : ". $questions->{$question}->{search_command} ."\n";
        $i++;
    }
}
sub printAnswers {
    my $i = 0;
    foreach my $answer (keys %$answers){
        print "answer $i : ". $answers->{$answer} ."\n";
        $i++;
    }
}
# Default error message and exit
sub default_error{
        print "Error, did you modify init script ?\n";
        exit;
}


###################################################### Following functions generates conf files for Kanopya
sub genLibkanopyaConf{
        my $tpl='templates/administrator.conf.tt';
        my $conf=$conf_dir.'administrator.conf';
        my %datas=(logdir => $answers->{log_directory}, internal_net_add => $answers->{internal_net_add}, internal_net_mask => $answers->{internal_net_mask}, dbip => $answers->{dbip}, dbport => $answers->{dbport});
        useTemplate(template => $tpl, datas => \%datas, conf => $conf);
}

sub genCoreConf{
        my $tpl='templates/executor.conf.tt';
        my $conf=$conf_dir.'executor.conf';
        my %datas=(logdir => $answers->{log_directory}, internal_net_add => $answers->{internal_net_add}, internal_net_mask => $answers->{internal_net_mask});
        useTemplate(template => $tpl, datas => \%datas, conf => $conf);
        #We generate executor's log configuration
        $tpl='templates/executor-log.conf.tt';
        $conf=$conf_dir.'executor-log.conf';
        %datas=(logdir => $answers->{log_directory});
        useTemplate(template => $tpl, datas => \%datas, conf => $conf);
}

sub genMonitorConf{
        my $tpl='templates/monitor.conf.tt';
        my $conf=$conf_dir.'monitor.conf';
        my %datas= (internal_net_add => $answers->{internal_net_add}, internal_net_mask => $answers->{internal_net_mask});
        useTemplate(template => $tpl, datas => \%datas, conf => $conf);
        #We generate monitor's log configuration
        $tpl='templates/monitor-log.conf.tt';
        $conf=$conf_dir.'monitor-log.conf';
        %datas=(logdir => $answers->{log_directory});
        useTemplate(template => $tpl, datas => \%datas, conf => $conf);
}

sub genOrchestratorConf{
        print "creating orchestrator.conf...";
        my $conf=$conf_dir.'orchestrator.conf';
        system("touch $conf") == 0 or die "error while touching orchestrator.conf: $!";
        print "done\n";
        print "filling orchestrator.conf...";
        open (FILE, ">$conf") or die "error while opening orchestrator.conf: $!";
        print FILE "<config time_step='20' rrd_base_dir='/var/cache/mcs/orchestrator/base' graph_dir='/tmp/orchestrator/graph'>\n<user name=\"admin\" password=\"admin\"/>\n</config>";
        close (FILE);
        print "done\n";

        #We generate orchestrator's log configuration
        my $tpl='templates/orchestrator-log.conf.tt';
        $conf=$conf_dir.'orchestrator-log.conf';
        my %datas=(logdir => $answers->{log_directory});
        useTemplate(template => $tpl, datas => \%datas, conf => $conf);
}

sub genStateManagerConf{
        my $tpl='templates/state-manager-log.conf.tt';
        my $conf=$conf_dir.'state-manager-log.conf';
        my %datas=(logdir => $answers->{log_directory});
        useTemplate(template => $tpl, datas => \%datas, conf => $conf);
}

sub genWebuiConf{
        my $tpl='templates/webui-log.conf.tt';
        my $conf=$conf_dir.'webui-log.conf';
        my %datas=(logdir => $answers->{log_directory});
        useTemplate(template => $tpl, datas => \%datas, conf => $conf);
}

sub useTemplate{
        my %args=@_;
        my $input=$args{template};
        my $dat=$args{datas};
        my $output=$args{conf};
        my $config = {
                INCLUDE_PATH => $conf_dir,
                INTERPOLATE  => 1,
                POST_CHOMP   => 1,
                EVAL_PERL    => 1,
        };
        my $template = Template->new($config);
        $template->process($input, $dat, $output) || do {
                print "error while generating $output: $!";
        };
}

#my $mcs_admin_nic_mac = `ip link list dev $main_nic_name | egrep "ether [0-9a-zA-Z]{2}:[0-9a-zA-Z]{2}:[0-9a-zA-Z]{2}:[0-9a-zA-Z]{2}:[0-9a-zA-Z]{2}:[0-9a-zA-Z]{2}" | cut -d' ' -f6`;

# Calculate free space on vg
#	my $command = "vgs $args{lvm2_vg_name} --noheadings -o vg_free --nosuffix --units M --rows";

#print "calculating the first host address available for this network...";
#my $network_addr = NetAddr::IP->new($mcs_internal_network, $mcs_internal_network_mask);
#my @c = split("/",$network_addr->first);
#$mcs_admin_internal_ip = $c[0];
#print "done (first host address is $mcs_admin_internal_ip)\n";
#print "setting up $main_nic_name ...";
#system ("ifconfig $main_nic_name $mcs_admin_internal_ip") == 0 or die "an error occured while trying to set up nic ($main_nic_name) address: $!";
#print "done\n";
