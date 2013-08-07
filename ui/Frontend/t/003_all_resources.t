use Test::More 'no_plan';
use strict;
use warnings;

# the order is important
use Frontend;
use Dancer::Test;
use REST::api;
use Data::Dumper;

use Log::Log4perl;
Log::Log4perl->easy_init({level=>'DEBUG', file=>'api.t.log', layout=>'%F %L %p %m%n'});


my $response = dancer_response(POST => '/login', { params => {login => 'admin', password => 'K4n0pY4'}});

my @api_resources = keys %REST::api::resources;
for my $resource_route (keys %REST::api::resources) {
    response_status_is ['GET' => "/api/$resource_route"], 200, "response status is 200 for GET /api/$resource_route";
}