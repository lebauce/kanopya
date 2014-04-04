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
    file   => 'basedb_virtual_on_demand.t.log',
    layout => '%F %L %p %m%n'
});

my $log = get_logger("");

my $testing = 1;

use Kanopya::Database;
use Node;

use TryCatch;
my $err;

Kanopya::Database::authenticate(login => 'admin', password => 'K4n0pY4');

main();

sub main {
    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    lives_ok {
        my $json = Node->find()->toJSON();
        if (exists $json->{puppet_manifest}) {
            die 'Virtual attribute "puppet_manifest" found in the json of a Node, without expand=pauppet_manifest specified.'
        }
    } 'Check that toJSON on a Node without expand=pauppet_manifest specified do not return attr puppet_manifest';

    lives_ok {
        my $json = Node->find()->toJSON(expand => [ 'puppet_manifest' ]);
        if (! exists $json->{puppet_manifest}) {
            die 'Virtual attribute "puppet_manifest" not found in the json of a Node, while expand=pauppet_manifest specified.'
        }
    } 'Check that toJSON on a Node while expand=pauppet_manifest specified return attr puppet_manifest';

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}
