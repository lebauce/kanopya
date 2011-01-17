#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/test.log', layout=>'%F %L %p %m%n'});
use Data::Dumper;

use_ok('Executor');
use_ok ('Administrator');
use_ok('Entity::Systemimage');


my $test_instantiation = "Instantiation test";

eval {
    Administrator::authenticate( login =>'admin', password => 'admin' );
    my @args = ();
    note ("Execution begin");
    my $executor = new_ok("Executor", \@args, "Instantiate an executor");

    # Test bad structure cluster
    note("Test Instanciation Error");
    throws_ok { Entity::Systemimage->new(
		    systemimage_name => 'MySystemImage Test',
		    systemimage_desc => 'Test whitespace in name',
		    distribution_id => 1) } qr/checkAttrs detect a wrong value/,
    $test_instantiation;

    ########################### Test cluster extended
    note("Test Motherboard extended");
    my $s1 = Entity::Systemimage->new(
		    systemimage_name => 'MySystemImageTest',
		    systemimage_desc => 'Testnowhitespace',
		    distribution_id => 1,
		    etc_device_id => 5,
		    root_device_id => 6,);

    isa_ok($s1, "Entity::Systemimage", $test_instantiation);

    $s1->save();
#    $m2->save();
    # Test cluster->get
    note( "Test Motherboard management");
    $s1->activate();
    $executor->execnround(run => 1);
    my $clone_s1 = Entity::Systemimage->get(id => $s1->getAttr(name=>'systemimage_id'));
    is ($clone_s1->getAttr(name=>'active'), 1, "Test if SystemImage is active");
    $s1->activate();
    throws_ok { $executor->execnround(run => 1) } 'Kanopya::Exception::Internal',
    "Activate a second time same systemimage";
    $s1->deactivate();
    $executor->execnround(run => 1);
    is ($s1->getAttr(name=>'active'), undef, "Deactivate Systemimage");
    $s1->delete();
    throws_ok { $clone_s1 = Entity::Systemimage->get(id => $s1->getAttr(name=>'systemimage_id'))} 'Kanopya::Exception::Internal',
    "Try to get a deleted motherboard";
    note("Test Systemimage.pm pod");
    pod_file_ok( '/opt/kanopya/lib/administrator/Entity/Systemimage.pm', 'stuff docs are valid POD' );

};
if($@) {
	my $error = $@;
	print Dumper $error;
};

