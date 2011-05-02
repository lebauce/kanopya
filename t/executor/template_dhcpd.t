#!/usr/bin/perl

use warnings;
use Data::Dumper;
use Log::Log4perl "get_logger";
use Test::More 'no_plan';

#Log::Log4perl->init('../Conf/log.conf');
#my $log = get_logger("executor");
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'STDOUT', layout=>'%F %L %p %m%n'});

use Template;

# some useful options (see below for full list)
my $config = {
    INCLUDE_PATH => '/templates/mcsdhcpd',
    INTERPOLATE  => 1,               # expand "$var" in plain text
    POST_CHOMP   => 1,               # cleanup whitespace 
    EVAL_PERL    => 1,               # evaluate Perl code blocks
    RELATIVE => 1,  		     # desactive par defaut
};

# create Template object
my $template = Template->new($config);



my @nodes = ({ip_address => "10.0.0.2", 
   	      mac_address => "00:1c:1c:c0:c9",
	      hostname=> "node002",
	      kernel_version => "2.6.39"},
   	     {ip_address => "10.0.0.3", 
	      mac_address => "00:2f:2f:2f:f4",
	      hostname=> "node003",
	      kernel_version => "2.6.32"});

my @subnets = ({net => "10.0.0.0", mask => "255.255.255.0", nodes => \@nodes},
{net => "10.0.1.0", mask => "255.255.255.0", nodes => \@nodes},
);

my $vars = {domain_name		=> "domaine.name.com",
   	    domain_name_server 	=> "10.0.0.254",
	    server_name		=> "node001",
	    server_ip		=> "10.0.0.1",
	    subnets		=> \@subnets,
   	   };
my $input = "dhcpd.conf.tt";
$template->process($input, $vars) || die $template->error;