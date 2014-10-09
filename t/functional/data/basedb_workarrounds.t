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
    layout => '%d [ %H - %P ] %p -> %M - %m%n'
});
my $log = get_logger("");

my $testing = 1;

use BaseDB;
use Kanopya::Database;
use General;
use Entity::Component;
use Entity::ServiceProvider::Cluster;
use Entity::User;

Kanopya::Database::authenticate(login => 'admin', password => 'K4n0pY4');

main();

sub main {

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    test_component_haproxy1s_listen_relation();
    test_prefeches();
    test_deprecated_sp();
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

sub test_prefeches {
    lives_ok {
        my $kcluster = Entity::ServiceProvider::Cluster->getKanopyaCluster();
        Entity::ServiceProvider->searchRelated(id      => $kcluster->id,
                                               filters => ['aggregate_conditions'],
                                               prefetch => ['left_combination']);

        Entity::User->search('prefetch' => ['profiles']);

    } 'Search with prefeches';
}

sub test_deprecated_sp {
    lives_ok {
        my $kcluster = Entity::ServiceProvider::Cluster->getKanopyaCluster();
        my $anycomponent = ($kcluster->components)[0];
        my $anynode = ($kcluster->nodes)[0];

        if (! $anycomponent->service_provider->isa("Entity::ServiceProvider::Cluster")) {
            die 'Getting the service provider from a component should return the concrete service provider type'
        }
        if (! $anynode->service_provider->isa("Entity::ServiceProvider::Cluster")) {
            die 'Getting the service provider from a node should return the concrete service provider type'
        }

    } 'Search with prefeches';
}
