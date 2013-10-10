use Test::More 'no_plan';

use strict;
use warnings;

# the order is important
use Frontend;
use APITestLib;
use Dancer::Test;
use REST::api;

use Log::Log4perl;
Log::Log4perl->easy_init({ level => 'DEBUG', file => '003_policies.log', layout => '%F %L %p %m%n' });


APITestLib::login();

use Data::Dumper;
my @api_resources = keys %REST::api::resources;
for my $resource_route ('hostingpolicy', 'storagepolicy', 'networkpolicy', 'scalabilitypolicy', 'systempolicy','billingpolicy', 'orchestrationpolicy') {

    # Get the attribute def from GET
    my $resource_info_resp = dancer_response(GET => "/api/attributes/$resource_route", {});
    print Dumper($resource_info_resp);
    my $from_get = Dancer::from_json($resource_info_resp->{content});

    # Get the attribute def from POST
    $resource_info_resp = dancer_response(POST => "/api/attributes/$resource_route", {});
    print Dumper($resource_info_resp);
    my $from_post = Dancer::from_json($resource_info_resp->{content});

    my $hashcmp = eq_hash($from_get, $from_post);
    ok($hashcmp == 1, "Attributes of $resource_route from GET are the same than from POST ones");
#    print Dumper($resource_info->{attributes})
}