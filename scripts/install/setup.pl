#!/usr/bin/perl -w
use strict;
use warnings;

use Kanopya::Exceptions;

use Getopt::Std;
use TryCatch;
use Log::Log4perl qw(:easy get_logger);

Log::Log4perl->easy_init({
    level  => 'DEBUG',
    file   => 'setup.log',
    layout => '%d [ %H - %P ] %p -> %M - %m%n'
});

sub print_usage {
    print "Usage: setup.pl\n";
    print "       setup.pl -d\n";
    print "       setup.pl -f yaml_file\n";
    print "       setup.pl -s file_to_generate\n";
    print "Process initial Kanopya configuration\n";
    exit(1);
}

my %opts = ();
getopts("df:s:", \%opts) or print_usage;

# Check operating system and load corresponding setup class
my $setup;

if ($^O eq 'linux') {
    if($< != 0) {
        die "You must be root to execute this script\n";
    }
    use Setup::Linux;
    $setup = Setup::Linux->new(%opts);
}
elsif ($^O eq 'MSWin32') {
    # TODO test admin privilieges
    use Setup::MSWin32;
    $setup = Setup::MSWin32->new(%opts);
}
else {
    die "$^O is not supported\n";
}

# if mode is default (-d command line parameter), do not ask user but 
#  automatically use default answers
# if mode is file (-f command line parameter), do not ask user but 
#  automatically use the provided file to take answers

# Show licence 

#if(not $setup->accept_licence()) {
#   exit(1);
#}

# Generate parameters files if required
if (defined $opts{s}) {
    try {
        $setup->serialize_parameters(output_file => $opts{s}, test => 1);
    }
    catch {
        throw Kanopya::Exception::IO(error => "Unable to create/write the specified file <$opts{s}> for parameters serialization.\n");
    }
}

# Ask parameters 
$setup->ask_parameters();

# Complete parameters with additionnal informations
$setup->complete_parameters();

# Process setup
$setup->process();

# Generate parameters files if required
if (defined $opts{s}) {
    $setup->serialize_parameters(output_file => $opts{s});
}
