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

my $hosts = dancer_response GET => '/api/host';
is $hosts->{status}, 200, 'response from GET on /api/host is 200';
my $hosts_content = Dancer::from_json($hosts->{content});

foreach my $host (@$hosts_content) {
    my $expanded_hosts = dancer_response GET => '/api/host',
                         { params => { expand       => 'host_manager.component',
                                       component_id => $host->{host_manager_id},
                           }
                         };
    my $expanded_hosts_content = Dancer::from_json($expanded_hosts->{content});

    foreach my $expand (@$expanded_hosts_content) {
      is $expand->{host_manager}->{component}->{component_id},
         $host->{host_manager_id},
         "deep expanded component filtered by host_manager_id $host->{host_manager_id} is right";
    }
}
