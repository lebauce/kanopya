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

# 1- PUT
my $hosts = dancer_response GET => '/api/host';
my $content = Dancer::from_json($hosts->{content});
my $host_id = $content->[0]->{host_id};

my $params_to_put = { "host_core" => "4", "host_ram" => "512" };

my $put = dancer_response PUT => '/api/host/' . $host_id, { params => $params_to_put };
is $put->{status}, "200", "response for put on /host/$host_id is 200";

my $put_content = Dancer::from_json($put->{content});
is $put_content->{status}, "success", "put updated host $host_id successfully";

my $host = dancer_response GET => '/api/host/' . $host_id;
my $host_content = Dancer::from_json($host->{content});

while (my ($param, $value) = each %$host_content) {
    if (defined $params_to_put->{$param}) {
        is $value, $params_to_put->{$param}, "param $param was successfully updated by PUT method on object $host_id";
    }
}
