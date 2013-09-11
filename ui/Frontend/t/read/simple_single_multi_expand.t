#!/usr/bin/perl

use Test::More 'no_plan';
use strict;
use warnings;

# the order is important
use Dancer::Test;
use Frontend;
use REST::api;
use APITestLib;

use Data::Dumper;
$DB::deep = 500;

use Log::Log4perl;
Log::Log4perl->easy_init({level=>'DEBUG', file=>'api.t.log', layout=>'%F %L %p %m%n'});

# Firstly login to the api
APITestLib::login();

my $get_hosts = dancer_response GET => '/api/host';
is $get_hosts->{status}, 200, "response for GET /api/host is 200";
my $hosts_content = Dancer::from_json($get_hosts->{content});

foreach my $host (@$hosts_content) {
    my $host_ifaces = $host->{ifaces};
    my $host_id = $host->{host_id};

    my $expand = dancer_response GET => '/api/host/' . $host_id, {params => {expand => 'ifaces'}};
    is $expand->{status}, 200, "response for GET /api/host/$host_id with expand ifaces is 200";
    my $expand_content = Dancer::from_json($expand->{content});

    if (scalar $host_ifaces > 0) {
        #check le nombre d'iface
        is scalar @{ $expand_content->{ifaces} },
           $host_ifaces,
           "expanded ifaces from GET /api/host match the number of iface on the host";
        #check que chacune des iface présente dans expand_content appartient bien a l'host
        my @matched;
        my @grep;
        foreach my $iface (0..$host_ifaces) {
            @grep = grep { $_->{host_id} == $host->{host_id}} @{ $expand_content->{ifaces} };
        }
        push @matched, @grep;
        is scalar @matched,
           $host_ifaces,
           "expanded ifaces from GET /api/host/$host_id are all correct expands";
    }
    else {
        is scalar @{ $expand_content->{ifaces} },
           '0',
           "ifaces expand from GET /api/host/$host_id is an empty array";
    }
}
