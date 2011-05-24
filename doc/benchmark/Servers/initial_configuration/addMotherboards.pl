#!/usr/bin/perl

# Take a file name as param
# The file contains list of mac adress
# This script enqueue operation AddMotherboard for each mac adress

use lib </opt/kanopya/lib/*>;

use Data::Dumper;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'STDOUT', layout=>'%F %L %p %m%n'});

use Administrator;
use Entity::Motherboard;

my %args = (login =>'admin', password => 'K4n0pY4');

Administrator::authenticate( %args );
my $adm = Administrator->new();

$data_file=$ARGV[0];
die "Need a file name param" if (not defined $data_file);
open(DATA, $data_file) || die("Could not open file '$data_file'!");
my $n = 1;
while (<DATA>) {
    if ($_ =~ /^([A-F0-9:]*)$/) {
	print "Add motherboard $1\n";

	my $mb = Entity::Motherboard->new(
	    motherboard_mac_address => $1, 
	    kernel_id => 1, 
	    motherboard_serial_number => "SN$n",
#	    powersupplyport_number => $n,
#           powersupplycard_id => 1,
	    motherboardmodel_id => 7,
	    processormodel_id => 2,
	    active => 1
	    );
	$mb->create();
	$n++;
	
    } else {
	chomp $_;
	print "Skip invalid: $_\n";
    }
}
close(DATA);




