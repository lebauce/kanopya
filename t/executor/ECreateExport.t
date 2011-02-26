#!/usr/bin/perl -w
use Data::Dumper;
use Log::Log4perl "get_logger";
use Test::More 'no_plan';


use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/test.log', layout=>'%F %L %p %m%n'});

use_ok(Administrator);
use_ok(Executor);
use_ok(Kanopya::Exceptions);
use_ok(Entity::Component::Export::Iscsitarget1);
eval {
    Administrator::authenticate( login =>'admin', password => 'admin' );
    my @args = ();
    note ("Execution begin");
    my $executor = new_ok("Executor", \@args, "Instantiate an executor");

    my $iscsitarget = Entity::Component::Export::Iscsitarget1->get(id => 3);
    $iscsitarget->createExport(export_name => "test",
    			       device => "/dev/vg1/root_DebianSystemImage2",
			       typeio => "fileio",
			       iomode => "ro");
#    $executor->execnround(run => 1);
}
