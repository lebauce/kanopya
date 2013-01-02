#!/usr/bin/perl -w

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'/vagrant/Bonding.t.log',
    layout=>'%F %L %p %m%n'
});


use Administrator;
use Entity::ServiceProvider::Inside::Cluster;
use Net::Ping;
use Ip;
use Entity::Iface;
use Kanopya::Tools::Retrieve;

eval {
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my $adm = Administrator->new;

    $cluster = Kanopya::Tools::Retrieve->retrieveCluster(criteria => {cluster_name => 'Bondage'});

    lives_ok {
        my $hosts = $cluster->getHosts();
        my @bonded_ifaces;
        foreach my $host (values %$hosts) {
            my @ifaces = grep { scalar @{ $_->slaves} > 0 } Entity::Iface->find(hash => {host_id => $host->id});
            push @bonded_ifaces, @ifaces;
        }

        my $ip;
        my $ping;
        my $pingable;
        foreach my $iface (@bonded_ifaces) {
            $ip = Ip->find(hash => {iface_id => $iface->id});
        	$ping = Net::Ping->new('icmp');
	        $pingable = $ping->ping($ip->ip_addr, 10);
	        $pingable ? $pingable : 0;
        }
    } 'ping bonded interface';

};
if($@) {
    my $error = $@;
    print $error."\n";
};
