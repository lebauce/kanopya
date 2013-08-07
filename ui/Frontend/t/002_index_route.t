use Test::More tests => 3;
use strict;
use warnings;

# the order is important
use Frontend;
use Dancer::Test;

route_exists [GET => '/'], 'a route handler is defined for /';
response_status_is ['GET' => '/'], 302, 'response status is 302 for / when not logged';

my $response = dancer_response(POST => '/login', { params => {login => 'admin', password => 'K4n0pY4'}});

response_status_is ['GET' => '/'], 200, 'response status is 200 for / after login';
