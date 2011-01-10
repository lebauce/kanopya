#!/usr/bin/perl -w

use lib qw(/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'STDOUT', layout=>'%F %L %p %m%n'});

use Test::More 'no_plan';
use Administrator;
use Data::Dumper;
use McsExceptions;

my $adm = Administrator->new( login =>'thom', password => 'pass' );

# Print sql queries
#BEGIN { $ENV{DBIC_TRACE} = 1 }


# TODO: deplacer les tests sur les entity dans Entity.t 

#
#	Test generic obj management
#
eval {
    note("Test Administrator connec")
    Administrator::authenticate( login =>'admin', password => 'admin' );
    my $adm1 = Administrator->new();
    my $adm1 = Administrator->new();
    

};
if($@) {
	my $error = $@;
	
	$adm->{db}->txn_rollback;
	print "$error";
	exit 233;
#	$error->rethrow(); # we wan't fail test if exception
};

