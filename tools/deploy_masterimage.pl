#!/usr/bin/perl -w

use strict;
use warnings;
use XML::Simple;

use Kanopya::Exceptions;
use Administrator;
use Operation;
use General;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($INFO);

# Get param
my $arg = $ARGV[0];
if (not defined $arg) {
    print "Usage: deploy_masterimage file.tar.bz\n";
    exit 1;
}

if(! -e $arg) {
    print "file $arg not found\n";
    exit 2;
}

my $conf = XMLin("/opt/kanopya/conf/executor.conf");
General::checkParams(args=>$conf->{user}, required=>["name","password"]);


my $adm = Administrator::authenticate(
    login    => $conf->{user}->{name},
	password => $conf->{user}->{password}
);

eval {
    Operation->enqueue(
        priority => 200,
        type     => 'DeployMasterimage',
        params   => { file_path => "$arg", keep_file => 1 },
    );
};

