#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Operation;
use Administrator;
use Kanopya::Exceptions;


use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/test.log', layout=>'%F %L %p %m%n'});

use Data::Dumper;
my $test_instantiation = "Instantiation test";

eval {
    Administrator::authenticate( login =>'admin', password => 'K4n0py4' );

    note("Infrastructure Import");
    my $new_op = Operation->enqueue(priority=>"200", type=>"AddInfrastructure", params=>{file_path=>"/tmp/drupal.json"});

};
if($@) {
	my $error = $@;
	print Dumper $error;
};

