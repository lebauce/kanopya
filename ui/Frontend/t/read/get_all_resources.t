use Test::More 'no_plan';
use strict;
use warnings;

# the order is important
use Frontend;
use Dancer::Test;
use REST::api;
use APITestLib;
use Test::Exception;

use Data::Dumper;

use Log::Log4perl;
Log::Log4perl->easy_init({level=>'DEBUG', file=>__FILE__.'.log', layout=>'%F %L %p %m%n'});


# Firstly login to the api
APITestLib::login();

lives_ok {
    for my $resource_route (keys %REST::api::resources) {
        my $rep = dancer_response GET => "/api/$resource_route";
        if ($rep->{status} ne 200) {
            die "GET /api/$resource_route wrong status => " . Dumper $rep->{status};
        }
    }
} "Get all resources";
