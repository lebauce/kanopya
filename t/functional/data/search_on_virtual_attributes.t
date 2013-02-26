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
    file   => 'search_on_virtual_attributes.log',
    layout => '%F %L %p %m%n'
});
my $log = get_logger("");

my $testing = 1;

use BaseDB;
use Entity::Host;

BaseDB->authenticate(login =>'admin', password => '_tamere23');

main();

sub main {
    if ($testing == 1) {
        BaseDB->beginTransaction;
    }

    my $ip = Entity::Host->find()->admin_ip;
    throws_ok {
        my $host = Entity::Host->find(hash => { admin_ip => '0.0.0.0' });
    } 'Kanopya::Exception::Internal::NotFound', 'Search return no hosts for virtual attribute adin_ip => 0.0.0.0';

    lives_ok {
        my $host = Entity::Host->find(hash => { admin_ip => $ip });
    } 'Search return one host for virtual attribute adin_ip => ' . $ip;

    if ($testing == 1) {
        BaseDB->rollbackTransaction;
    }
}
