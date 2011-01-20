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
    note("Test Systemimage Instanciation Error");
    throws_ok { Entity::Systemimage->new(
		    systemimage_name => 'MySystemImage Test',
		    systemimage_desc => 'Test whitespace in name',
		    distribution_id => 1) } qr/checkAttrs detect a wrong value/,
    $test_instantiation;

    ########################### Test Systemimage instanciation
    note("Test Systemimage instanciation");
    my $s1 = Entity::Systemimage->new(
		    systemimage_name => 'MySystemImageTest',
		    systemimage_desc => 'Testnowhitespace',
		    distribution_id => 1);
    isa_ok($s1, "Entity::Systemimage", $test_instantiation);

    note( "Test Systemimage creation");
    $s1->create();
    $executor->execnround(run => 1);
    my $s2 = Entity::Systemimage->getSystemimage(hash => {systemimage_name => 'MySystemImageTest'});
    isa_ok($s2, "Entity::Systemimage", $test_instantiation);

    note( "Test Systemimage activation");
    $s2->activate();
    $executor->execnround(run => 1);
    $s2 = Entity::Systemimage->get(id => $s2->getAttr(name=>'systemimage_id'));
    is ($s2->getAttr(name=>'active'), 1, "Test if SystemImage is active");

    note( "Test Systemimage activation Error");
    $s2->activate();
    throws_ok { $executor->execnround(run => 1) } 'Kanopya::Exception::Internal',
    "Activate a second time same systemimage";

    note( "Test Systemimage deactivation");
    $s2 = Entity::Systemimage->get(id => $s2->getAttr(name=>'systemimage_id'));
    $s2->deactivate();
    $executor->execnround(run => 1);
    $s2 = Entity::Systemimage->get(id => $s2->getAttr(name=>'systemimage_id'));
    is ($s2->getAttr(name=>'active'), 0, "Deactivate Systemimage");

    note("Test Systemimage clone");
    $s2->clone(systemimage_name => "Systemimagecloned", systemimage_desc=>"Systemimagecloned");
    $executor->execnround(run => 1);
    my $clone_s2 = Entity::Systemimage->getSystemimage(hash => {systemimage_name => 'Systemimagecloned'});
    isa_ok($clone_s2, "Entity::Systemimage", $test_instantiation);

    $s2->remove();
    $clone_s2->remove();
    $executor->execnround(run => 2);

    throws_ok { $s2 = Entity::Systemimage->get(id => $s2->getAttr(name=>'systemimage_id'))} 'Kanopya::Exception::Internal',
    "Try to get a deleted motherboard";
    note("Test Systemimage.pm pod");
    pod_file_ok( '/opt/kanopya/lib/administrator/Entity/Systemimage.pm', 'stuff docs are valid POD' );

};
if($@) {
	my $error = $@;
	print Dumper $error;
};

