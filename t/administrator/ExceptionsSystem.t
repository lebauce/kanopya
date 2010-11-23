#!/usr/bin/perl -w

use FindBin qw($Bin);
use lib "$Bin/../Lib";

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'STDOUT', layout=>'%F %L %p %m%n'});
use Data::Dumper;
use Test::More 'no_plan';
use Administrator;

eval {
	my $adm = Administrator->new( login =>'thom', password => 'pass' );
};
if ($@) {
	print Dumper $@;
   }