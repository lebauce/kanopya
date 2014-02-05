#!/usr/bin/perl -w
use strict;
use warnings;

use General;
use Kanopya::Exceptions;
use Kanopya::Database;
use Setup::Linux;

use JSON;
use Getopt::Std;
use XML::Simple;
use TryCatch;
use Data::Dumper;



sub print_usage {
    print "Usage: load_services.pl services_file.json\n";
    print "       load_services.pl -f services_file.json\n";
    print "Load services and policies initial environment.\n";
    exit(1);
}

my %opts = ();
getopts("f", \%opts) or print_usage;

my $main_file = $ARGV[0];
if (not defined $main_file) {
    print_usage;
    exit 1;
}
elsif (! -e $main_file) {
    print "File $main_file not found\n";
    exit 2;
}

# Authenticate to Kanopya
my $conf = XMLin("/opt/kanopya/conf/executor.conf");
General::checkParams(args => $conf->{user}, required => [ "name","password" ]);


Kanopya::Database::authenticate(login    => $conf->{user}->{name},
                                password => $conf->{user}->{password});

Kanopya::Database::beginTransaction;

try {
    Setup::Linux->loadPoliciesAndServices(main_file => $main_file);
}
catch ($err) {
    Kanopya::Database::rollbackTransaction;
    $err->rethrow();
}

Kanopya::Database::commitTransaction;


