#!usr/bin/perl

use Test::Harness qw(&runtests);

# trouver comment faire plus generique que ça
use lib "Administrator/Lib";
use lib "Executor/Lib";

@modules = ( 'Administrator', 'Executor' );
@test_files = ();

foreach $module (@modules) {
	@files = <$module/t/*.t>;
	push  @test_files, @files;	
}

runtests @test_files;