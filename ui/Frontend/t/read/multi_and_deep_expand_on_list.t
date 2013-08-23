#!/usr/bin/perl

use Test::More 'no_plan';
use strict;
use warnings;

# the order is important
use Dancer::Test;
use Frontend;
use REST::api;
use Data::Dumper;
$DB::deep = 500;

use Log::Log4perl;
Log::Log4perl->easy_init({level=>'DEBUG', file=>'api.t.log', layout=>'%F %L %p %m%n'});

my $login = dancer_response(POST => '/login', { params => {login => 'admin', password => 'K4n0pY4'}});

my $hosts = dancer_response GET => '/api/host/', { params => { expand => 'host_manager.component,node' } };
is $hosts->{status}, 200, "response for GET /api/host/ with deep expand host_manager.component and node";
my $hosts_content = Dancer::from_json($hosts->{content});

foreach my $host (@$hosts_content) {
    my $host_manager_id = $host->{host_manager_id};
    my $host_id = $host->{host_id};

    my $deep_node = $host->{node};
    my $deep_component = $host->{host_manager}->{component};
    my $deep_host_manager = $host->{host_manager};

    is $deep_node->{host_id},$host_id, "node returned by expand is the right one";

    is $deep_host_manager->{component_id},
    $host_manager_id,
    "host manager returned by first level of deep expand is the right one";

    is $deep_component->{component_id},
    $deep_host_manager->{component_id},
    "component returned by second level of deep expand is the right one";

    my $straight_component = dancer_response GET => '/api/component/' . $deep_component->{component_id};
    is $straight_component->{status}, 200, "response for GET /api/component/$deep_component->{component_id} is 200";
    my $component_content = Dancer::from_json($straight_component->{content});

    is $component_content->{component_type_id},
    $deep_component->{component_type_id},
    "deep expanded component type match component's one returned from straight GET";
}
