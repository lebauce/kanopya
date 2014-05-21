#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;

use File::Basename;
use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level  => 'DEBUG',
    file   => basename(__FILE__) . '.log',
    layout => '%d [ %H - %P ] %p -> %M - %m%n'
});

my $log = get_logger("");

use Kanopya::Database;

# For components lib oaded at runtime
use BaseDB;

use Kanopya::Tools::TestUtils 'expectedException';


use_ok ('Entity::Component::Dhcpd3');
use_ok ('Entity::Host');


Kanopya::Database::authenticate(login => 'admin', password => 'K4n0pY4');

main();

sub main {
    Kanopya::Database::beginTransaction;

    my $dhcpd = Entity::Component::Dhcpd3->find();
    my $host = Entity::Host->find(hash => { 'ifaces.iface_pxe' => 1 });

    my $dhcpd_host;
    lives_ok {
        $dhcpd_host = $dhcpd->addHost(host => $host);
    } 'Add host ' . $host->label . ' to dhcpd component';

    lives_ok {
        $dhcpd_host->reload();
    } 'Get the created dhcpd host entry';

    Kanopya::Database::rollbackTransaction;
}
1;