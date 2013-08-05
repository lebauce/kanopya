#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;

sub print_usage {
    print "Usage: setup.pl\n";
    print "       setup.pl -d\n";
    print "       setup.pl -f yamlfile\n";
    print "Process initial Kanopya configuration\n";
    exit(1);
}

my %opts = ();
getopts("df:", \%opts) or print_usage;

# check operating system and load corresponding setup class
my $setup;

if($^O eq 'linux') {
    if($< != 0) {
        die "You must be root to execute this script\n";
    }
    use Setup::Linux;
    $setup = Setup::Linux->new(%opts);
} 
elsif($^O eq 'MSWin32') {
    # TODO test admin privilieges
    use Setup::MSWin32;
    $setup = Setup::MSWin32->new(%opts);
} else {
    die "$^O is not supported\n";
}

# if mode is default (-d command line parameter), do not ask user but 
#  automatically use default answers
# if mode is file (-f command line parameter), do not ask user but 
#  automatically use the provided file to take answers

# show licence 

#if(not $setup->accept_licence()) {
#   exit(1);
#}

# ask parameters 
$setup->ask_parameters();

# complete parameters with additionnal informations
$setup->complete_parameters();

# process setup
$setup->process();
