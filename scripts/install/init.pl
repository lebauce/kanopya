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
welcome();
getConf();
printAnswers();

sub welcome {
    my $validate_licence;

    print "Welcome on Kanopya\n";
    print "This script will configure your Kanopya instance\n";
    print "We advise that Kanopya instance will be installed on a dedicated server\n";
    print "First please validate the user licence";
    `cat LICENCE`;
    print "Do you accept the licence ? (y/n)\n";
    chomp($validate_licence= <STDIN>);
    if ($validate_licence ne 'y'){
        exit;
    }
    print "Please answer to the following question\n";
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
        # if answer is searchable and has a n answer detection, allow user to choose good answer
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
                print "Error you enter a value out of answer scope.";
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
        print "Error, Do you modify init script ?\n";
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
        print "Error, Do you modify init script ?\n";
        exit;
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


