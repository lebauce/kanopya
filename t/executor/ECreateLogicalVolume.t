#!/usr/bin/perl -w
use Data::Dumper;
use Log::Log4perl "get_logger";
use Test::More 'no_plan';


use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/test.log', layout=>'%F %L %p %m%n'});

use_ok(Administrator);
use_ok(Executor);
use_ok(Kanopya::Exceptions);
use_ok(Entity::Component::Storage::Lvm2);
eval {
    Administrator::authenticate( login =>'admin', password => 'admin' );
    my @args = ();
    note ("Execution begin");
    my $executor = new_ok("Executor", \@args, "Instantiate an executor");

    my $lvm = Entity::Component::Storage::Lvm2->get(id => 1);
    $lvm->createLogicalVolume(disk_name => "test",
    			       size => 10,
			       filesystem => "ext3");
#    $executor->execnround(run => 1);
}
