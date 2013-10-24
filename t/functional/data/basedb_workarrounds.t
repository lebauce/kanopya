#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({
    level  => 'DEBUG',
    file   => 'basedb_workarrounds.log',
    layout => '%F %L %p %m%n'
});
my $log = get_logger("");

my $testing = 1;

use BaseDB;
use Kanopya::Database;
use General;
use Entity::Component;


Kanopya::Database::authenticate(login => 'admin', password => 'K4n0pY4');

main();

sub main {

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    test_component_haproxy1s_listen_relation();

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}


sub test_component_haproxy1s_listen_relation {
    # Search on component inner classes

    my $component = Entity::Component->find();

    lives_ok {
        my @test = $component->haproxy1s_listen;

    } 'Get relation <haproxy1s_listen> on a Entity::Component instance';
}

